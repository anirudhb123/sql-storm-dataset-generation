
WITH CTE_Customer_Supplier AS (
    SELECT 
        c.c_custkey,
        c.c_name AS customer_name,
        c.c_acctbal,
        s.s_suppkey,
        s.s_name AS supplier_name, 
        s.s_acctbal AS supplier_acctbal,
        CASE 
            WHEN c.c_acctbal IS NULL THEN 'No Balance'
            WHEN c.c_acctbal > s.s_acctbal THEN 'Customer Richer'
            WHEN c.c_acctbal < s.s_acctbal THEN 'Supplier Richer'
            ELSE 'Equal Balance'
        END AS balance_comparison
    FROM 
        customer c
    JOIN 
        supplier s ON c.c_nationkey = s.s_nationkey
    WHERE 
        c.c_acctbal >= 0.0
), 
CTE_Order_Aggregate AS (
    SELECT 
        o.o_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
),
CTE_Line_Item_Summary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_cost,
        COUNT(*) AS line_count,
        MAX(l.l_shipdate) AS last_ship_date
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)

SELECT 
    c.customer_name,
    c.supplier_name,
    o.total_orders,
    o.total_spent,
    l.line_count,
    l.last_ship_date,
    c.balance_comparison
FROM 
    CTE_Customer_Supplier c
LEFT JOIN 
    CTE_Order_Aggregate o ON c.c_custkey = o.o_custkey
FULL OUTER JOIN 
    CTE_Line_Item_Summary l ON l.l_orderkey = (SELECT o_orderkey FROM orders WHERE o_custkey = c.c_custkey LIMIT 1)
WHERE 
    (o.total_spent IS NOT NULL OR l.line_count IS NULL OR c.c_acctbal IS NULL)
ORDER BY 
    CASE WHEN c.balance_comparison = 'Equal Balance' THEN 0 ELSE 1 END,
    o.total_spent DESC, 
    l.line_count ASC 
LIMIT 50;
