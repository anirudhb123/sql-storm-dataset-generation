WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name, 
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > 10000
),
HighValueParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, p.p_mfgr, 
           CASE 
               WHEN p.p_retailprice > 200 THEN 'High'
               WHEN p.p_retailprice BETWEEN 100 AND 200 THEN 'Medium'
               ELSE 'Low'
           END AS price_category
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT ps.ps_supplycost 
                       FROM partsupp ps 
                       WHERE ps.ps_availqty < 10)
),
OrderStats AS (
    SELECT o.o_custkey, SUM(o.o_totalprice) AS total_spent, 
           COUNT(DISTINCT o.o_orderkey) AS total_orders,
           AVG(o.o_totalprice) AS avg_order_value
    FROM orders o
    GROUP BY o.o_custkey
    HAVING AVG(o.o_totalprice) > 500
)
SELECT dd.nation_name, 
       AVG(ps.s_acctbal) AS avg_supplier_balance, 
       COUNT(DISTINCT hp.p_partkey) AS total_high_value_parts,
       os.total_spent
FROM SupplierDetails sd
LEFT JOIN HighValueParts hp ON sd.s_suppkey = (SELECT ps.ps_suppkey 
                                                FROM partsupp ps 
                                                WHERE ps.ps_partkey IN (SELECT p.p_partkey 
                                                                        FROM part p 
                                                                        WHERE p.p_mfgr = 'ManufacturerX') 
                                                LIMIT 1)
LEFT JOIN OrderStats os ON sd.s_suppkey = os.o_custkey
JOIN nation dd ON sd.nation_name = dd.n_name
WHERE sd.rank = 1
GROUP BY dd.nation_name, os.total_spent
ORDER BY avg_supplier_balance DESC, total_high_value_parts DESC
LIMIT 10
UNION ALL
SELECT 'Total' AS nation_name, 
       AVG(sd.s_acctbal) AS avg_supplier_balance, 
       COUNT(DISTINCT hp.p_partkey) AS total_high_value_parts,
       NULL AS total_spent
FROM SupplierDetails sd
JOIN HighValueParts hp ON sd.s_suppkey = (SELECT ps.ps_suppkey 
                                           FROM partsupp ps 
                                           WHERE ps.ps_partkey IN (SELECT p.p_partkey 
                                                                   FROM part p 
                                                                   WHERE p.p_size IS NULL) 
                                           LIMIT 1)
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.o_custkey = sd.s_suppkey)
GROUP BY sd.s_suppkey
HAVING COUNT(DISTINCT hp.p_partkey) > 0
ORDER BY total_high_value_parts DESC;
