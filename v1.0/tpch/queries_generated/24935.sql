WITH RankedParts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_retailprice, 
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100)
),
CustomerSpend AS (
    SELECT c.c_nationkey, 
           SUM(o.o_totalprice) AS total_spend,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY c.c_nationkey
),
SupplierAvailability AS (
    SELECT ps.ps_partkey,
           SUM(ps.ps_availqty) AS total_available,
           MIN(ps_supplycost) AS min_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
FinalAnalysis AS (
    SELECT rp.p_partkey,
           rp.p_name,
           rp.p_retailprice,
           CASE 
               WHEN ca.total_spend IS NULL THEN 'No Orders'
               ELSE CAST(ca.total_spend AS VARCHAR) 
           END AS total_spend_category,
           sa.total_available,
           sa.min_cost
    FROM RankedParts rp
    LEFT JOIN CustomerSpend ca ON rp.p_partkey = (SELECT ps.ps_partkey 
                                                   FROM partsupp ps 
                                                   WHERE ps.ps_partkey = rp.p_partkey
                                                   FETCH FIRST 1 ROW ONLY)
    LEFT JOIN SupplierAvailability sa ON rp.p_partkey = sa.ps_partkey
    WHERE (rp.rn <= 3 OR total_available IS NOT NULL)
    ORDER BY rp.p_retailprice DESC, sa.total_available ASC
)
SELECT f.*, 
       CASE 
           WHEN f.total_available > 10 THEN 'Abundant'
           WHEN f.total_available BETWEEN 1 AND 10 THEN 'Limited'
           ELSE 'Out of Stock'
       END AS stock_status,
       COALESCE(f.total_spend_category, 'N/A') AS final_spend_desc
FROM FinalAnalysis f
WHERE f.total_available IS NOT NULL
UNION ALL
SELECT f.*, 
       'Supplier Analysis' AS stock_status,
       'N/A' AS final_spend_desc
FROM FinalAnalysis f
WHERE f.total_available IS NULL AND f.total_spend_category IS NULL
ORDER BY p_retailprice DESC, stock_status;
