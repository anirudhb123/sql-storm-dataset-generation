WITH RECURSIVE SupplyChain AS (
    SELECT ps_partkey, ps_suppkey, ps_availqty, ps_supplycost, 1 AS level
    FROM partsupp
    WHERE ps_availqty > 0
    UNION ALL
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost, sc.level + 1
    FROM partsupp ps
    INNER JOIN SupplyChain sc ON ps.ps_partkey = sc.ps_partkey
    WHERE ps.ps_availqty > 0 AND sc.level < 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate, SUM(l.l_quantity) AS total_quantity
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE c.c_acctbal IS NOT NULL AND o.o_orderdate >= DATE '2022-01-01'
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate
),
SupplierStatistics AS (
    SELECT s.s_suppkey, s.s_name, COUNT(DISTINCT ps.ps_partkey) AS part_count, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > 500 AND s.s_name IS NOT NULL
    GROUP BY s.s_suppkey, s.s_name
)
SELECT 
    c.c_name AS customer_name,
    o.o_orderkey AS order_id,
    COALESCE(NULLIF(o.o_totalprice, 0), 'N/A') AS total_price,
    ss.part_count AS total_parts_supplied,
    ss.avg_supplycost AS average_supply_cost,
    SUM(COALESCE(l.l_discount, 0)) OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate ROWS BETWEEN UNBOUNDED preceding AND CURRENT ROW) AS cumulative_discount,
    STRING_AGG(DISTINCT CONCAT_WS(', ', l.l_shipmode, l.l_shipinstruct), '; ') AS shipping_info
FROM CustomerOrders o
JOIN customer c ON o.c_custkey = c.c_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN SupplierStatistics ss ON l.l_suppkey = ss.s_suppkey
LEFT JOIN region r ON r.r_regionkey = (
    SELECT n.n_regionkey
    FROM nation n
    WHERE n.n_nationkey = c.c_nationkey
)  
WHERE r.r_name IS NOT NULL
GROUP BY c.c_name, o.o_orderkey, o.o_totalprice, ss.part_count, ss.avg_supplycost
ORDER BY o.o_orderdate DESC, total_price DESC
LIMIT 100;
