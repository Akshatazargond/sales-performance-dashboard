create database sales
use sales;

## 1. Analyze Sales Performance
### A. Top-Performing Sales Agents by Total Closed Deal Value

SELECT 
    sales_agent,
    COUNT(*) AS total_deals,
    SUM(close_value) AS total_revenue
FROM sales_pipelinee
WHERE deal_stage = 'Won'
GROUP BY sales_agent
ORDER BY total_revenue DESC;

##B. Best-Selling Products

SELECT 
    product,
    COUNT(*) AS deal_count,
    SUM(close_value) AS total_revenue
FROM sales_pipelinee
WHERE deal_stage = 'Won'
GROUP BY product
ORDER BY total_revenue DESC;

##C. High-Value Deals Using Percentile

WITH value_distribution AS (
    SELECT 
        close_value,
        NTILE(3) OVER (ORDER BY close_value DESC) AS value_segment
    FROM sales_pipelinee
    WHERE deal_stage = 'Won'
)
SELECT 
    sp.sales_agent,
    COUNT(*) AS high_value_deals
FROM sales_pipelinee sp
JOIN value_distribution vd ON sp.close_value = vd.close_value
WHERE vd.value_segment = 1 -- Top 33% deals
GROUP BY sp.sales_agent
ORDER BY high_value_deals DESC;

# 2. Understand Deal Success & Failure
## A. Conversion Rate by Sales Agent

SELECT 
    sales_agent,
    COUNT(CASE WHEN deal_stage = 'Won' THEN 1 END) AS won_deals,
    COUNT(*) AS total_deals,
    ROUND(100.0 * COUNT(CASE WHEN deal_stage = 'Won' THEN 1 END) / COUNT(*), 2) AS conversion_rate
FROM sales_pipelinee
GROUP BY sales_agent
ORDER BY conversion_rate DESC;

#B. Lost Deals Reason Analysis (if reasons available; here just counts)

SELECT 
    account,
    COUNT(*) AS lost_deals
FROM sales_pipelinee
WHERE deal_stage = 'Lost'
GROUP BY account
ORDER BY lost_deals DESC;

# 3. Predict Churn Risk
# A. Accounts with High Lost Deal Percentage

SELECT 
    account,
    COUNT(*) AS total_deals,
    COUNT(CASE WHEN deal_stage = 'Lost' THEN 1 END) AS lost_deals
FROM sales_pipelinee
GROUP BY account
ORDER BY total_deals DESC;


#B. Accounts with Long Time Since Last Won Deal

DESCRIBE sales_pipelinee;

SELECT 
    account,
    MAX(CASE WHEN deal_stage = 'Won' THEN STR_TO_DATE(close_date, '%m/%d/%Y') END) AS last_won_deal_date,
    DATEDIFF(CURRENT_DATE, MAX(CASE WHEN deal_stage = 'Won' THEN STR_TO_DATE(close_date, '%m/%d/%Y') END)) AS days_since_last_win
FROM sales_pipelinee
GROUP BY account
HAVING last_won_deal_date IS NOT NULL
ORDER BY days_since_last_win DESC;



# 4. Detect Seasonal Sales Trends

SELECT 
    YEAR(STR_TO_DATE(close_date, '%m/%d/%Y')) AS year,
    MONTH(STR_TO_DATE(close_date, '%m/%d/%Y')) AS month,
    SUM(close_value) AS monthly_revenue
FROM sales_pipelinee
WHERE deal_stage = 'Won'
  AND close_date != '1/0/1900'  -- Exclude invalid date
GROUP BY YEAR(STR_TO_DATE(close_date, '%m/%d/%Y')), MONTH(STR_TO_DATE(close_date, '%m/%d/%Y'))
ORDER BY year, month;



# 5. Enhance Decision-Making (Join with Sales Team & Accounts)
# Revenue by Region and Sector

SELECT 
    st.regional_office,
    a.sector,
    SUM(sp.close_value) AS total_revenue
FROM sales_pipelinee sp
JOIN sales_teams st ON sp.sales_agent = st.sales_agent
JOIN accounts a ON sp.account = a.account
WHERE sp.deal_stage = 'Won'
GROUP BY st.regional_office, a.sector
ORDER BY total_revenue DESC;

