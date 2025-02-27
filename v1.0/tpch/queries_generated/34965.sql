WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01'
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
PartSupplierCost AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
RegionParts AS (
    SELECT DISTINCT p.p_partkey, r.r_name, p.p_retailprice
    FROM part p
    LEFT JOIN supplier s ON p.p_partkey = s.s_suppkey
    LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE p.p_retailprice IS NOT NULL
)
SELECT oh.o_orderkey, oh.o_totalprice, oh.order_rank, 
       COALESCE(sp.nation_name, 'Unknown') AS supplier_nation,
       rp.r_name AS part_region, rp.p_retailprice,
       COALESCE(pc.total_supply_cost, 0) AS total_supply_cost,
       CASE 
           WHEN oh.o_totalprice > 10000 THEN 'High Value' 
           ELSE 'Regular' 
       END AS order_value_indicator
FROM OrderHierarchy oh
LEFT JOIN SupplierDetails sp ON oh.o_custkey = sp.s_suppkey
LEFT JOIN RegionParts rp ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sp.s_suppkey)
LEFT JOIN PartSupplierCost pc ON rp.p_partkey = pc.ps_partkey
WHERE oh.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
  AND (oh.o_orderdate IS NOT NULL OR oh.o_orderdate < CURRENT_DATE)
ORDER BY oh.o_orderdate DESC, oh.o_totalprice ASC;
