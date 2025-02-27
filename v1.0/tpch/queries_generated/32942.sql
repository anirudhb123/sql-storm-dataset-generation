WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0

    UNION ALL

    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN SupplyChain sc ON sc.ps_partkey = ps.ps_partkey
    WHERE sc.ps_availqty < ps.ps_availqty
),
TopRegions AS (
    SELECT r.r_name, SUM(o.o_totalprice) AS total_revenue
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '2022-01-01'
    GROUP BY r.r_name
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, 
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_retailprice IS NOT NULL AND p.p_size > 0
)
SELECT r.r_name, COUNT(DISTINCT sc.s_suppkey) AS supplier_count, 
       AVG(sc.ps_supplycost) AS average_supply_cost,
       SUM(td.p_retailprice) AS total_part_value,
       COALESCE(TRIM(td.p_name), 'Unknown') AS part_name
FROM SupplyChain sc
LEFT JOIN TopRegions r ON r.total_revenue > 10000
LEFT JOIN PartDetails td ON sc.ps_partkey = td.p_partkey AND td.price_rank <= 10
GROUP BY r.r_name
HAVING COUNT(DISTINCT sc.s_suppkey) > 5
ORDER BY total_part_value DESC NULLS LAST;
