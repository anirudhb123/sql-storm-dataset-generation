WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, SUM(ps.ps_availqty) AS total_available_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
),
CustomerRank AS (
    SELECT c.c_custkey, c.c_name, c.c_mktsegment, 
           RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(o.o_totalprice) DESC) AS total_price_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_mktsegment
)
SELECT DISTINCT s.s_name, p.p_name, cd.c_mktsegment,
                CASE 
                    WHEN p.total_available_qty IS NULL THEN 'Not Available'
                    ELSE 'Available'
                END AS availability,
                cd.total_price_rank
FROM SupplierHierarchy s
LEFT JOIN PartDetails p ON s.s_suppkey = p.p_partkey
JOIN CustomerRank cd ON cd.c_custkey = s.s_nationkey
WHERE (s.s_acctbal > 1000 OR s.s_nationkey IS NULL)
  AND (p.avg_supply_cost < (SELECT AVG(ps.ps_supplycost) FROM partsupp ps WHERE ps.ps_availqty > 0))
ORDER BY cd.total_price_rank, s.s_name;
