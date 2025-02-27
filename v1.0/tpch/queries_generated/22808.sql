WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 10
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, 
           ps.ps_supplycost, p.p_retailprice,
           (SELECT COUNT(*) FROM lineitem l 
            WHERE l.l_partkey = p.p_partkey AND l.l_quantity IS NOT NULL) AS total_lineitems
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size BETWEEN 10 AND 30
),
AggregateResults AS (
    SELECT pd.p_partkey, pd.p_name, 
           SUM(pd.ps_supplycost * pd.ps_availqty) AS total_supply_value,
           AVG(pd.p_retailprice) AS avg_retail_price,
           MAX(pd.total_lineitems) AS max_lineitems
    FROM PartDetails pd
    GROUP BY pd.p_partkey, pd.p_name
)
SELECT a.p_partkey, a.p_name, a.total_supply_value, 
       COALESCE(r.r_name, 'Unknown') AS region_name,
       CASE 
           WHEN a.avg_retail_price > 100.00 THEN 'Expensive'
           WHEN a.avg_retail_price BETWEEN 50.00 AND 100.00 THEN 'Moderate'
           ELSE 'Cheap'
       END AS price_category,
       SUM(CASE 
           WHEN COALESCE(s.s_acctbal, 0) > 5000 THEN 1 
           ELSE 0 
       END) OVER (PARTITION BY a.p_partkey) AS wealthy_suppliers
FROM AggregateResults a
LEFT JOIN supplier s ON s.s_acctbal >= 5000
FULL OUTER JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE a.avg_retail_price <= (SELECT AVG(p.p_retailprice) FROM part p)
AND r.r_name NOT LIKE '.*(?:North|West).*' 
GROUP BY a.p_partkey, a.p_name, r.r_name
HAVING COUNT(DISTINCT s.s_suppkey) > 2
ORDER BY a.total_supply_value DESC, a.p_name ASC
LIMIT 10;
