WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, n.n_name AS nation_name, 
           CASE 
               WHEN s.s_acctbal < 1000 THEN 'Low'
               WHEN s.s_acctbal BETWEEN 1000 AND 5000 THEN 'Medium'
               ELSE 'High'
           END AS acctbal_category
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
PartSupplierStats AS (
    SELECT ps.ps_partkey, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
           SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
DetailedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_mfgr, p.p_container, 
           p.p_size, p.p_retailprice, ps.supplier_count, ps.total_supply_cost
    FROM part p
    JOIN PartSupplierStats ps ON p.p_partkey = ps.ps_partkey
)
SELECT dp.p_partkey, dp.p_name, dp.p_brand, dp.p_mfgr, dp.p_container, 
       dp.p_size, dp.p_retailprice, sd.nation_name, sd.acctbal_category
FROM DetailedParts dp
JOIN SupplierDetails sd ON sd.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    WHERE ps.ps_partkey = dp.p_partkey
)
ORDER BY dp.p_retailprice DESC, sd.nation_name ASC;
