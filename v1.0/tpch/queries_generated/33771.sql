WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderpriority, o_orderdate, o_totalprice, 1 AS level
    FROM orders
    WHERE o_orderdate >= '2023-01-01'
    
    UNION ALL
    
    SELECT o2.o_orderkey, o2.o_custkey, o2.o_orderpriority, o2.o_orderdate, o2.o_totalprice, oh.level + 1
    FROM orders o2
    JOIN OrderHierarchy oh ON o2.o_custkey = oh.o_custkey
    WHERE o2.o_orderdate > oh.o_orderdate
),
SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderValues AS (
    SELECT 
        oh.o_orderkey,
        oh.o_custkey,
        oh.o_orderdate,
        oh.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY oh.o_custkey ORDER BY oh.o_orderdate DESC) AS rn
    FROM OrderHierarchy oh
)
SELECT 
    r.r_name,
    n.n_name,
    c.c_name,
    SUM(COALESCE(ov.o_totalprice, 0)) AS total_order_value,
    COALESCE(sp.total_supply_cost, 0) AS total_supply_cost,
    COUNT(DISTINCT ov.o_orderkey) AS number_of_orders,
    CAST(SUM(COALESCE(ov.o_totalprice, 0)) AS DECIMAL(12, 2)) / NULLIF(COUNT(DISTINCT ov.o_orderkey), 0) AS avg_order_value
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN OrderValues ov ON c.c_custkey = ov.o_custkey AND ov.rn <= 5
LEFT JOIN SupplierPerformance sp ON c.c_custkey = sp.s_suppkey
WHERE n.n_name IS NOT NULL
GROUP BY r.r_name, n.n_name, c.c_name
HAVING SUM(COALESCE(ov.o_totalprice, 0)) > 10000
ORDER BY total_order_value DESC, number_of_orders ASC;
