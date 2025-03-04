# CUSTOMER BUYING BEHAVIOUR ANALYSIS 

## Goal of the project
A retail company wants to analyze customer buying behavior to optimize customer segmentation and improve marketing strategies. The dataset contains transaction records, including CustomerID, PurchaseDate, TransactionAmount, ProductInformation, OrderID, and Location.
The goal is to implement RFM (Recency, Frequency, and Monetary) Analysis to:

Segment customers based on their purchasing behavior.
Identify high-value customers and at-risk customers.
Provide actionable insights to improve retention and maximize revenue.



## Analysis Approach
## Data Preparation & Review:

Modified table schema to ensure correct data types.
Reviewed sample data and checked the date range.
## RFM Metrics Calculation:

Recency: Days since last purchase (DATEDIFF(CURDATE(), MAX(PurchaseDate))).
Frequency: Total number of transactions per customer (COUNT(OrderID)).
Monetary Value: Total amount spent (SUM(TransactionAmount)).
## Statistical Analysis of RFM Metrics:

Calculated min, max, median, and quartiles for Recency, Frequency, and Monetary Value to understand distribution.
## Customer Segmentation Using RFM Scoring:

Assigned Recency, Frequency, and Monetary scores (NTILE(5) function).
Created RFM Segments (Best Customers, Loyal Customers, At Risk, etc.).
## Value Segmentation Analysis:

Categorized customers into Low, Mid, High, and Top Tier Value based on average RFM scores.
Created a view (rfm_customer_segments) for further analysis.
## Final Insights & Recommendations:

Identified that 36.47% of customers are in the Low Value segment, requiring re-engagement efforts.
Best Customers (4.14%) and Big Spenders (15.86%) need exclusive retention strategies.
At-Risk (22.75%) and Lost Customers (17.82%) require targeted offers and outreach.


## Result:
✅ Improved Customer Insights: Clear understanding of customer spending behavior.
✅ Optimized Marketing Strategy: Focus on retaining high-value customers and re-engaging lost ones.
✅ Data-Driven Decision Making: Segmentation helps in personalizing promotions, loyalty programs, and improving revenue.

## Datasets Used
The datasets used include:
CUSTOMER PURCHASE BEHAVIUOR ANALYSIS DATA SET



## Tools and Technologies used
The tools used in this project include:
- MYSQL, power bi

## Authors
- Rajashekhar Hipparagi- [Github Profile](https://github.com/Rajashekhar7259)
