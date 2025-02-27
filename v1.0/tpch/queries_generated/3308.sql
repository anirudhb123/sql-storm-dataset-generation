WITH supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_availqty) DESC) AS rank_within_nation
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
top_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_availqty) > 10000
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) IS NOT NULL
),
lineitem_details AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey, l.l_partkey
)
SELECT 
    cs.c_name AS Customer_Name,
    ss.s_name AS Supplier_Name,
    l.net_revenue AS Lineitem_Revenue,
    COALESCE(ss.total_avail_qty, 0) AS Available_Quantity,
    CASE 
        WHEN cs.order_count > 5 THEN 'Frequent Customer'
        ELSE 'Infrequent Customer'
    END AS customer_type
FROM 
    customer_orders cs
LEFT JOIN 
    top_suppliers ss ON cs.c_custkey = ss.s_suppkey
JOIN 
    lineitem_details l ON cs.order_count = (SELECT COUNT(*) FROM orders o WHERE o.o_orderkey = l.l_orderkey)
WHERE 
    ss.rank_within_nation = 1 OR ss.rank_within_nation IS NULL
ORDER BY 
    cs.total_spent DESC, l.net_revenue DESC;
