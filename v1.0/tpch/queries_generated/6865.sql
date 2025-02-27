WITH supplier_summary AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT p.p_partkey) AS unique_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
customer_orders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
supply_and_order_analysis AS (
    SELECT
        cs.c_custkey,
        cs.c_name,
        ss.s_suppkey,
        ss.s_name AS supp_name,
        ss.total_supply_value,
        cs.total_orders,
        cs.total_spent,
        CASE 
            WHEN cs.total_spent > ss.total_supply_value THEN 'High Spending'
            WHEN cs.total_spent <= ss.total_supply_value AND cs.total_orders > 5 THEN 'Moderate Spending'
            ELSE 'Low Spending'
        END AS spending_category
    FROM 
        customer_orders cs
    JOIN 
        supplier_summary ss ON ss.unique_parts_supplied > 10
)
SELECT 
    supp_name,
    spending_category,
    COUNT(DISTINCT c_custkey) AS customer_count,
    AVG(total_spent) AS avg_spent,
    SUM(total_supply_value) AS total_supply_value_sum
FROM 
    supply_and_order_analysis
GROUP BY 
    supp_name, spending_category
ORDER BY 
    total_supply_value_sum DESC, customer_count DESC;
