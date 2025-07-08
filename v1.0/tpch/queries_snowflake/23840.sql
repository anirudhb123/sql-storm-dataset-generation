
WITH supplier_summary AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
           COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
recent_orders AS (
    SELECT o.o_orderkey, 
           o.o_custkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATEADD('YEAR', -1, CAST('1998-10-01' AS DATE))
    GROUP BY o.o_orderkey, o.o_custkey
),
nation_region AS (
    SELECT n.n_nationkey, 
           n.n_regionkey, 
           CONCAT(n.n_name, ' - ', r.r_name) AS nation_with_region
    FROM nation n
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT ns.nation_with_region,
       ss.s_name,
       ss.total_supply_value,
       ros.total_order_value,
       CASE 
           WHEN ros.order_rank = 1 THEN 'Most Recent'
           ELSE 'Older Order'
       END AS order_status,
       COUNT(DISTINCT ps.ps_partkey) FILTER (WHERE ps.ps_availqty < 50) AS low_stock_parts
FROM supplier_summary ss
JOIN recent_orders ros ON ss.s_suppkey = ros.o_custkey
JOIN nation_region ns ON ns.n_nationkey = ros.o_custkey
LEFT JOIN partsupp ps ON ss.s_suppkey = ps.ps_suppkey
WHERE ss.total_supply_value > (SELECT AVG(total_supply_value) FROM supplier_summary)
GROUP BY ns.nation_with_region, ss.s_name, ss.total_supply_value, ros.total_order_value, ros.order_rank
HAVING COUNT(ps.ps_partkey) > 0 AND
       SUM(ps.ps_availqty) IS NOT NULL
ORDER BY ns.nation_with_region, ss.total_supply_value DESC, ros.total_order_value DESC;
