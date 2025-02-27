WITH RECURSIVE PartHierarchy AS (
    SELECT p_partkey, p_name, p_mfgr, p_brand, p_type, p_size, 
           p_retailprice, p_comment, 1 AS hierarchy_level
    FROM part
    WHERE p_size < (SELECT AVG(p_size) FROM part)

    UNION ALL

    SELECT p.partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, 
           p.p_size, p.p_retailprice, p.p_comment, ph.hierarchy_level + 1
    FROM part p
    INNER JOIN PartHierarchy ph ON p.p_size < ph.p_size
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= DATEADD(month, -6, CURRENT_DATE)
)
SELECT p.p_partkey, p.p_name, ps.total_supply_cost, os.o_totalprice, 
       CASE 
           WHEN os.o_totalprice IS NULL THEN 'No Orders'
           WHEN p.p_retailprice > (SELECT AVG(p_retailprice) FROM part) THEN 'High Price'
           ELSE 'Normal Price' 
       END AS price_category,
       IFNULL(n.n_name, 'Unknown') AS nation_name
FROM part p
LEFT JOIN part p2 ON p.p_partkey = p2.p_partkey AND p.p_size = p2.p_size
LEFT JOIN SupplierStats ps ON p.p_partkey = ps.s_suppkey
FULL OUTER JOIN OrderSummary os ON ps.s_suppkey = os.o_orderkey
LEFT JOIN nation n ON ps.s_suppkey = n.n_nationkey
WHERE (p.p_name LIKE '%widget%' OR p.p_comment IS NOT NULL)
  AND (ps.total_supply_cost IS NOT NULL OR os.o_totalprice IS NULL)
ORDER BY p.p_partkey, ps.total_supply_cost DESC
FETCH FIRST 100 ROWS ONLY;
