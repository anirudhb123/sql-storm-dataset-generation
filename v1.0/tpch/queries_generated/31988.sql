WITH RECURSIVE part_hierarchy AS (
    SELECT p_partkey, p_name, p_mfgr, 
           CAST(p_name AS varchar(100)) AS full_name,
           1 AS level
    FROM part
    WHERE p_size = (SELECT MIN(p_size) FROM part)
    
    UNION ALL
    
    SELECT p.p_partkey, p.p_name, p.p_mfgr,
           CAST(CONCAT(ph.full_name, ' > ', p.p_name) AS varchar(100)),
           ph.level + 1
    FROM part_hierarchy ph
    JOIN part p ON p.p_size > (SELECT MIN(p_size) FROM part) 
              AND p.p_partkey < ph.p_partkey
), 
supplier_avg_cost AS (
    SELECT ps.ps_suppkey, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
),
filtered_orders AS (
    SELECT o.o_orderkey, o.o_totalprice,
           SUM(li.l_extendedprice * (1 - li.l_discount)) AS revenue
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE li.l_returnflag = 'N'
    AND o.o_orderdate BETWEEN '2021-01-01' AND '2021-12-31'
    GROUP BY o.o_orderkey, o.o_totalprice
)
SELECT ph.p_name, 
       ph.full_name,
       COALESCE(sa.avg_supply_cost, 0) AS average_supply_cost,
       fo.revenue,
       CASE 
           WHEN fo.revenue IS NULL THEN 'No Sales'
           WHEN fo.revenue > 10000 THEN 'High Revenue'
           ELSE 'Regular Revenue'
       END AS revenue_category
FROM part_hierarchy ph
LEFT JOIN supplier_avg_cost sa ON ph.p_partkey = sa.ps_suppkey
FULL OUTER JOIN filtered_orders fo ON ph.p_partkey = fo.o_orderkey
WHERE ph.level > 0
ORDER BY ph.level, ph.p_name;
