# 🛒 Maven Fuzzy Factory SQL Project

This project is built around the **Maven Fuzzy Factory eCommerce database**, a simplified schema designed for practicing SQL queries and analytics. It provides a realistic foundation for analyzing website traffic, customer orders, product performance, and refunds.

Dataset download: [Maven Fuzzy Factory Database on Kaggle](https://www.kaggle.com/datasets/mohammedgalex/maven-fuzzy-factory-database)

---

## 📊 Dataset Overview

The database contains the following core tables:

- **Orders** → Customer purchases with order ID, timestamp, user ID, session ID, primary product, item count, price (USD), and cost of goods sold (USD).  
- **Order Items** → Breakdown of each order into individual items, linked to products.  
- **Order Item Refunds** → Logs refunds with refund amount and order item ID.  
- **Products** → Product metadata including product ID, name, and release date.  
- **Website Sessions** → Captures visits with session ID, timestamp, user ID, repeat session flag, UTM parameters, device type, and http_referer.  
- **Website Page Views** → Tracks pages viewed during a session, useful for funnel and navigation analysis.  

---

## 🔑 Business Concepts

### **Traffic Source Analysis**
- Understand where customers come from (email, social media, search, direct traffic).  
- Measure **conversion rates** to identify high-quality traffic sources.  
- Use cases: budget allocation, campaign comparison, eliminating wasted spend, scaling high-performing channels.  

### **Bid Optimization**
- Optimize marketing spend by analyzing conversion rates and revenue per click.  
- Identify underperforming segments to reduce bids, and high-performing segments to increase bids.  
- Consider subsegments like **mobile vs desktop traffic**.  

### **Trend Analysis**
- Use SQL date functions (`MONTH`, `WEEK`, `YEAR`) with `GROUP BY` to analyze performance over time.  
- Summarize sessions, orders, or revenue by time periods.  
- Enables storytelling of business performance trends.  

### **Website Content Analysis**
- Identify the most viewed pages to prioritize improvements.  
- Find the most common **entry pages** (landing pages).  
- Evaluate page performance against business objectives.  
- Use **temporary tables** for multi-step analysis.  

### **Product Sales Analysis**
- Understand the contribution of each product to overall business performance.  
- Metrics include:  
  - **Order Volume** → Number of orders per product.  
  - **Revenue** → Sum of `price_usd`.  
  - **Margin** → Revenue minus `cogs_usd`.  
  - **Average Order Value (AOV)** → Average revenue per order.  
- Professional insight: Focus not only on revenue but also on **margin**, since profitability varies across products.  

### **Repeat Behavior Analysis**
- Analyze repeat visits and purchases to identify valuable customers.  
- Key elements:  
  - **is_repeat_session flag** → Tracks whether a session is first-time or repeat.  
  - **user_id** → Links multiple sessions to the same customer.  
- Use cases:  
  - Measure frequency of repeat visits.  
  - Identify channels driving repeat customers.  
  - Avoid double-paying for returning customers in marketing campaigns.  
- SQL concept: **DATEDIFF()** helps measure time between events (sessions, orders, refunds).  

### **Channel Portfolio Optimization**
- Analyze the entire portfolio of marketing channels (email, social, search, direct).  
- Goals:  
  - Understand session and order volume by channel.  
  - Compare conversion performance across channels.  
  - Optimize bids and allocate marketing spend efficiently.  
- Key tool: **UTM parameters** in the sessions table, joined to orders for conversion analysis.  
- Professional tip: Become an expert in the sessions table — it contains rich data on user behavior, devices, and repeat visits.  

### **Seasonality & Business Patterns**
- Identify recurring patterns in traffic and sales (daily, weekly, monthly, quarterly).  
- Use cases:  
  - **Day-parting analysis** → Plan staffing needs by time of day or day of week.  
  - **Seasonal demand analysis** → Prepare for spikes (e.g., holidays) or slowdowns.  
- SQL date functions: `QUARTER()`, `MONTH()`, `WEEK()`, `WEEKDAY()`, `HOUR()`.  
- Helps anticipate future trends and optimize operations.  

---

## ⚙️ Project Structure

- **/Scripts** → SQL scripts for traffic source analysis, bid optimization, trend analysis, product sales, repeat behavior, channel portfolio optimization, and seasonality.   
- **README.md** → Project overview and dataset reference.  

---

## 📐 Schema Relationships

- **Orders ↔ Order Items ↔ Products**  
- **Order Items ↔ Order Item Refunds**  
- **Orders ↔ Website Sessions ↔ Website Page Views**

This structure mirrors real-world eCommerce databases, making it an excellent foundation for practicing SQL queries, analytics, and business intelligence reporting.

---

## 🚀 Getting Started

1. Download the dataset from Kaggle: [Maven Fuzzy Factory Database](https://www.kaggle.com/datasets/mohammedgalex/maven-fuzzy-factory-database).  
2. Import the database into your SQL environment (MySQL, PostgreSQL, or SQL Server).  
3. Explore the schema using `DESCRIBE` or `INFORMATION_SCHEMA` queries.  
4. Run queries from the `/Scripts` folder to practice traffic source analysis, bid optimization, trend analysis, product sales, repeat behavior, channel portfolio optimization, and seasonality insights.  

---

## 🧑‍💻 Contribution

Feel free to fork this repository, add new queries, or extend the analysis with dashboards and reports. Contributions that improve documentation, add advanced SQL techniques, or provide visualization examples are welcome.

