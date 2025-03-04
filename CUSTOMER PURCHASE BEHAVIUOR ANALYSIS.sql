
USE RFM;

ALTER TABLE transactions
MODIFY CustomerID BIGINT, 
MODIFY PurchaseDate DATETIME,
MODIFY TransactionAmount DECIMAL(12,2),
MODIFY ProductInformation VARCHAR(100),
MODIFY OrderID BIGINT,
MODIFY Location VARCHAR(100);

/*
Customer buying behaviour Analysis | Value Segmentation | Customer Segmentation

Skills used: Joins, Unions, CTE's, Temp Tables,Views, Windows Functions, Aggregate Functions, CASE, Converting Data Types

--==> This means insights/inferences
*/

-- review the data
SELECT 
    CustomerID,
    PurchaseDate,
    TransactionAmount,
    ProductInformation,
    OrderID,
    Location
FROM
    transactions
LIMIT 10; 

-- View range of date
SELECT 
    MAX(PurchaseDate), MIN(PurchaseDate)
FROM
    transactions;    
    
-- data includes a range of purchase dates, with the latest purchase being on December 31, 2024, 


-- Calculating the RFM (Recency, Frequency, and Monetary) metrics for each customer to analyze their purchasing behavior and optimize customer segmentation.

SELECT 
    customerid,
    DATEDIFF(CURDATE(), MAX(PurchaseDate)) AS recency,  -- Days since last purchase
    COUNT(OrderID) AS Frequency,   -- Total number of orders per customer
    SUM(TransactionAmount) AS Monetary_Value  -- Total Amount spent by per customer
FROM
    transactions
GROUP BY customerid;

-- ******************************************************************************************************************************


-- Summary Statistics for RFM Metrics (Recency, Frequency, and Monetary Value) of Customers

WITH rfm AS (
    SELECT 
        customerid,
        COUNT(transactionid) AS Frequency,  -- Number of transactions (F)
        SUM(TransactionAmount) AS Monetary_Value,       -- Total amount spent (M)
        DATEDIFF(CURDATE(), MAX(PurchaseDate)) AS Recency -- Days since last purchase (R)
    FROM transactions
    GROUP BY customerid
),
quartiles AS (
    SELECT 
        RFM_Type,
        MIN(Value) AS Min,
        MAX(CASE WHEN quartile = 1 THEN Value END) AS Q1,
        MAX(CASE WHEN quartile = 2 THEN Value END) AS Median,
        MAX(CASE WHEN quartile = 3 THEN Value END) AS Q3,
        MAX(Value) AS Max
    FROM (
        SELECT 
            'Frequency' AS RFM_Type, Frequency AS Value, NTILE(4) OVER (ORDER BY Frequency) AS quartile FROM rfm
        UNION ALL
        SELECT 
            'Monetary Value', Monetary_Value, NTILE(4) OVER (ORDER BY Monetary_Value) FROM rfm
        UNION ALL
        SELECT 
            'Recency', Recency, NTILE(4) OVER (ORDER BY Recency) FROM rfm
    ) AS subquery
    GROUP BY RFM_Type
)
SELECT * FROM quartiles;

-- Customers exhibit a wide range of behaviors. The Frequency metric indicates most customers make between 9 to 13 purchases, with a few making up to 24 purchases.
-- Monetary Value shows a significant variation in spending, with the median value around 5471.37, but some customers spending as much as 13864.27.
-- Recency suggests that most customers last purchased around 66-103 days ago, but there are customers with recency as high as 362 days, which could imply potential churn or long gaps between purchases.*/

-- *******************************************************************************************************************************

--  RFM (Recency, Frequency, Monetary) Scores for each customers
WITH rfm AS (
    SELECT 
        customerid,
        DATEDIFF(CURDATE(), MAX(PurchaseDate)) AS Recency,
        COUNT(transactionid) AS Frequency,
        SUM(TransactionAmount) AS Monetary_Value
    FROM transactions
    GROUP BY customerid
),
rfm_scores AS (
    SELECT 
        customerid,
        Recency,
        Frequency,
        Monetary_Value,
        -- Assign Recency Score (Lower recency is better, so reverse the quartiles)
        NTILE(5) OVER (ORDER BY Recency DESC) AS Recency_Score,
        -- Assign Frequency Score (Higher is better)
        NTILE(5) OVER (ORDER BY Frequency ASC) AS Frequency_Score,
        -- Assign Monetary Score (Higher is better)
        NTILE(5) OVER (ORDER BY Monetary_Value ASC) AS Monetary_Score
    FROM rfm
)
SELECT * FROM rfm_scores
ORDER BY customerid; -- Recency_Score DESC, Frequency_Score DESC, Monetary_Score DESC;
     

-- *******************************************************************************************************************************

-- RFM Analysis for Customer Segmentation: Categorizing Customers into Distinct Segments Based on Recency, Frequency, and Monetary Scores
-- Drop the table if it already exists
DROP TABLE IF EXISTS rfm_segments;

-- Create a permanent table to store RFM segments
CREATE TABLE rfm_segments (
    customerid INT PRIMARY KEY,
    Recency INT,
    Frequency INT,
    Monetary_Value DECIMAL(16,2),
    Recency_Score INT,
    Frequency_Score INT,
    Monetary_Score INT,
    RFM_Segment VARCHAR(50)
);

-- Insert calculated RFM segments into the permanent table
INSERT INTO rfm_segments
WITH rfm AS (
    SELECT 
        customerid,
        DATEDIFF(CURDATE(), MAX(PurchaseDate)) AS Recency,
        COUNT(transactionid) AS Frequency,
        SUM(TransactionAmount) AS Monetary_Value
    FROM transactions
    GROUP BY customerid
),
rfm_scores AS (
    SELECT 
        customerid,
        Recency,
        Frequency,
        Monetary_Value,
        NTILE(5) OVER (ORDER BY Recency DESC) AS Recency_Score,
        NTILE(5) OVER (ORDER BY Frequency ASC) AS Frequency_Score,
        NTILE(5) OVER (ORDER BY Monetary_Value ASC) AS Monetary_Score
    FROM rfm
)
SELECT 
    r.*,
    -- Define RFM Segments
    CASE 
        WHEN Recency_Score = 5 AND Frequency_Score = 5 AND Monetary_Score = 5 THEN 'Best Customers'
        WHEN Recency_Score >= 4 AND Frequency_Score >= 4 THEN 'Loyal Customers'
        WHEN Recency_Score = 5 THEN 'New Customers'
        WHEN Frequency_Score >= 4 AND Monetary_Score >= 4 THEN 'Big Spenders'
        WHEN Recency_Score <= 2 AND Frequency_Score <= 2 AND Monetary_Score <= 2 THEN 'Lost Customers'
        WHEN Recency_Score <= 3 AND Frequency_Score <= 3 THEN 'At Risk'
        WHEN Recency_Score >= 4 THEN 'Potential Loyalist'
        ELSE 'Others'
    END AS RFM_Segment
FROM rfm_scores r;




SELECT 
    Recency_Score, 
    MIN(Recency) AS Min_Recency, 
    MAX(Recency) AS Max_Recency, 
    AVG(Recency) AS Avg_Recency
FROM rfm_segments
GROUP BY Recency_Score
ORDER BY Recency_Score;

SELECT 
    Frequency_Score, 
    MIN(Frequency) AS Min_Frequency, 
    MAX(Frequency) AS Max_Frequency, 
    AVG(Frequency) AS Avg_Frequency
FROM rfm_segments
GROUP BY Frequency_Score
ORDER BY Frequency_Score;

SELECT 
    Monetary_Score, 
    MIN(Monetary_Value) AS Min_Monetary, 
    MAX(Monetary_Value) AS Max_Monetary, 
    AVG(Monetary_Value) AS Avg_Monetary
FROM rfm_segments
GROUP BY Monetary_Score
ORDER BY Monetary_Score;

-- The analysis of Recency, Frequency, and Monetary scores reveals the following key insights:

-- Recency:

-- Min_Recency (Score 1) ranges from 112 to 363 days, with an average of 144.99 days. Customers in this group have not interacted recently, indicating potential disengagement.
-- Max_Recency (Score 5) ranges from 57 to 65 days, with an average of 60.96 days. This group represents customers who have made recent purchases, indicating a high level of engagement.

-- Frequency:

-- Min_Frequency (Score 1) spans from 2 to 8 transactions, with an average of 6.71 transactions. These customers have made fewer transactions, but this may indicate low-frequency or infrequent shoppers.
-- Max_Frequency (Score 5) ranges from 14 to 24 transactions, with an average of 15.96 transactions, signifying customers who are consistently making purchases, which could imply loyalty or high engagement.

-- Monetary Value:

-- Min_Monetary (Score 1) ranges from $55.16 to $3913.4, with an average of $3073.58 spent. These are the customers with the lowest spending, possibly the least valuable in terms of revenue.
-- Max_Monetary (Score 5) ranges from $7244.22 to $13,864.27, with an average of $8506.66. Customers in this segment are the highest spenders, representing a key revenue source for the business.

-- *******************************************************************************************************************************

-- Creating an RFM Customer Segmentation View: Categorizing Customers Based on Average RFM Scores and Defining Value Segments
-- Drop the view if it already exists
DROP VIEW IF EXISTS rfm_customer_segments;

-- Create the View for Analytics
CREATE VIEW rfm_customer_segments AS
SELECT 
    customerid,
    Recency,
    Frequency,
    Monetary_Value,
    Recency_Score,
    Frequency_Score,
    Monetary_Score,
    -- Calculate Average RFM Score
    (Recency_Score + Frequency_Score + Monetary_Score) / 3 AS Avg_RFM_Score,
    
    -- Define Value Segments based on Avg RFM Score
    CASE 
        WHEN (Recency_Score + Frequency_Score + Monetary_Score) / 3 >= 4.5 THEN 'Top Tier'
        WHEN (Recency_Score + Frequency_Score + Monetary_Score) / 3 >= 3.5 THEN 'High Value'
        WHEN (Recency_Score + Frequency_Score + Monetary_Score) / 3 >= 2.5 THEN 'Mid Value'
        ELSE 'Low Value'
    END AS Value_Segment,

    -- Define Customer Segments based on Individual RFM Scores
    CASE 
        WHEN Recency_Score = 5 AND Frequency_Score = 5 AND Monetary_Score = 5 THEN 'Best Customers'
        WHEN Recency_Score >= 4 AND Frequency_Score >= 4 THEN 'Loyal Customers'
        WHEN Recency_Score = 5 THEN 'New Customers'
        WHEN Frequency_Score >= 4 AND Monetary_Score >= 4 THEN 'Big Spenders'
        WHEN Recency_Score <= 2 AND Frequency_Score <= 2 AND Monetary_Score <= 2 THEN 'Lost Customers'
        WHEN Recency_Score <= 3 AND Frequency_Score <= 3 THEN 'At Risk'
        WHEN Recency_Score >= 4 THEN 'Potential Loyalist'
        ELSE 'Others'
    END AS Customer_Segment
FROM rfm_segments;






SELECT 
    Value_Segment, 
    COUNT(customerid) AS Customer_Count,
    ROUND(100.0 * COUNT(customerid) / (SELECT COUNT(*) FROM rfm_customer_segments), 2) AS Percentage
FROM rfm_customer_segments
GROUP BY Value_Segment
ORDER BY Customer_Count DESC;

-- Conclusion:
-- Low Value (36.47%): Largest group, requiring re-engagement efforts.
-- High Value (27.76%): Moderately engaged and valuable; nurture with targeted offers.
-- Mid Value (26%): Potential for growth with the right incentives.
-- Top Tier (9.77%): Small but highly valuable; maintain with exclusive experiences.

-- Recommendations:
-- Re-engage Low Value customers through targeted campaigns.
-- Encourage High and Mid Value customers to increase spending with loyalty incentives.
-- Retain Top Tier customers with premium offers.
-- Continuously track behavior to prevent valuable customers from becoming disengaged.


SELECT 
    Customer_Segment, 
    COUNT(customerid) AS Customer_Count,
    ROUND(100.0 * COUNT(customerid) / (SELECT COUNT(*) FROM rfm_customer_segments), 2) AS Percentage
FROM rfm_customer_segments
GROUP BY Customer_Segment
ORDER BY Customer_Count DESC;

-- Conclusion:
-- At Risk (22.75%) and Lost Customers (17.82%) make up a significant portion, requiring urgent re-engagement efforts.
-- Loyal Customers (16.41%) and Big Spenders (15.86%) represent valuable groups, with potential for increased loyalty.
-- Potential Loyalist (10.12%) and New Customers (9.31%) should be nurtured to become more engaged.
-- Best Customers (4.14%) are critical, needing special attention to maintain high value.

-- Recommendations:
-- Re-engage At Risk & Lost Customers with offers and personalized outreach.
-- Enhance Loyalty for Loyal & Big Spenders with VIP perks and exclusive deals.
-- Convert Potential Loyalists & New Customers through tailored promotions and onboarding.
-- Maintain Best Customers with personalized service and exclusive rewards.


SELECT 
    Value_Segment,
    Customer_Segment,
    COUNT(customerid) AS Customer_Count,
    ROUND(100.0 * COUNT(customerid) / SUM(COUNT(customerid)) OVER (PARTITION BY Value_Segment), 2) AS Percentage
FROM rfm_customer_segments
GROUP BY Value_Segment, Customer_Segment
ORDER BY Value_Segment, Customer_Count DESC;


-- Conclusion:
-- High Value Segment: Dominated by Big Spenders and Loyal Customers. Focus on retaining and rewarding these high-revenue groups.
-- Low Value Segment: Large portion of Lost and At Risk customers. Target them with re-engagement strategies to reduce churn.
-- Mid Value Segment: Mainly At Risk and Potential Loyalists. Proactive engagement can help convert them into higher-value customers.
-- Top Tier: Consists of Loyal and Best Customers, who should be treated as VIPs for continued loyalty and advocacy.

-- Recommendations:
-- Prioritize retention for High Value and Top Tier customers.
-- Use re-engagement campaigns for Lost and At Risk customers.
-- Nurture Potential Loyalists to convert them into Loyal Customers.
-- Focus on increasing Big Spenders in the Mid Value segment to boost loyalty.

     
