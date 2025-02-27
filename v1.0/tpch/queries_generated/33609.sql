WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_orderdate, o_totalprice, 1 AS level
    FROM orders
    WHERE o_orderstatus = 'O'
    
    UNION ALL

    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
)

SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    c.c_name AS customer_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    COUNT(DISTINCT o.o_orderkey) AS number_of_orders,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank,
    MAX(CASE WHEN l.l_shipdate > '2023-01-01' THEN l.l_shipdate END) AS last_shipment_date,
    COALESCE(SUM(NULLIF(ps.ps_supplycost, 0)), 0) AS total_supply_cost,
    COUNT(DISTINCT CASE WHEN c.c_mktsegment = 'BUILDING' THEN c.c_custkey END) AS building_cust_count
FROM 
    region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
LEFT JOIN (
    SELECT 
        DISTINCT o_orderkey,
        COUNT(*) OVER (PARTITION BY o_custkey) AS order_count
    FROM orders
    WHERE o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
) AS HighValueOrders ON o.o_orderkey = HighValueOrders.o_orderkey
WHERE 
    l.l_shipmode IN ('AIR', 'GROUND') 
    AND (n.n_name LIKE '%land%' OR n.n_name IS NULL)
GROUP BY r.r_name, n.n_name, c.c_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY total_sales DESC;
