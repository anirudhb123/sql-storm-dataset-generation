WITH RECURSIVE order_hierarchy AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_clerk, 
        1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O' 
    
    UNION ALL
    
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_clerk, 
        oh.level + 1
    FROM orders o
    JOIN order_hierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderstatus = 'F'
),
supplier_summary AS (
    SELECT 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_nationkey
),
lineitem_summary AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        AVG(l.l_quantity) AS avg_quantity
    FROM lineitem l
    GROUP BY l.l_orderkey
),
customer_avg_spending AS (
    SELECT 
        c.c_nationkey, 
        AVG(o.o_totalprice) AS avg_spending
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_nationkey
)
SELECT 
    r.r_name,
    COALESCE(ss.total_cost, 0) AS supplier_cost,
    COALESCE(lis.net_revenue, 0) AS revenue,
    COALESCE(cas.avg_spending, 0) AS avg_customer_spending
FROM region r
LEFT JOIN supplier_summary ss ON r.r_regionkey = ss.s_nationkey
LEFT JOIN (
    SELECT l.l_orderkey, SUM(l.l_extendedprice) AS net_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
) lis ON ss.s_nationkey = lis.l_orderkey
LEFT JOIN customer_avg_spending cas ON r.r_regionkey = cas.c_nationkey
WHERE r.r_name IS NOT NULL
ORDER BY r.r_name;
