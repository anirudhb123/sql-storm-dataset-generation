WITH RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT p2.p_size FROM part p2 WHERE p2.p_container IS NOT NULL)
),
SupplierStats AS (
    SELECT s.s_suppkey, AVG(s.s_acctbal) AS avg_acctbal, 
           COUNT(DISTINCT ps.ps_partkey) AS total_parts,
           SUM(CASE WHEN s.s_acctbal IS NULL THEN 1 ELSE 0 END) AS null_acctbal_count
    FROM supplier s 
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
KeyOrders AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('F', 'P')
    GROUP BY o.o_orderkey, o.o_custkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
CustomerBalance AS (
    SELECT c.c_custkey, c.c_acctbal, 
           CASE WHEN c.c_acctbal IS NULL THEN 'No Balance' 
                WHEN c.c_acctbal < 1000 THEN 'Low Balance' 
                ELSE 'Sufficient Balance' END AS balance_status
    FROM customer c
)
SELECT rp.p_name, rp.p_brand, s.avg_acctbal, cs.balance_status,
       CASE WHEN rp.brand_rank IS NULL THEN 'No Ranking' ELSE CAST(rp.brand_rank AS VARCHAR) END AS brand_rank,
       COUNT(k.o_orderkey) AS order_count,
       SUM(CASE WHEN s.null_acctbal_count > 0 THEN 1 ELSE 0 END) AS suppliers_with_null_balance
FROM RankedParts rp
LEFT JOIN SupplierStats s ON s.total_parts > 0
LEFT JOIN KeyOrders k ON k.o_custkey IN (SELECT c_custkey FROM CustomerBalance cb WHERE cb.balance_status = 'Sufficient Balance')
JOIN CustomerBalance cs ON cs.c_custkey = k.o_custkey
WHERE rp.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_brand = rp.p_brand)
GROUP BY rp.p_name, rp.p_brand, s.avg_acctbal, cs.balance_status, rp.brand_rank
HAVING COUNT(k.o_orderkey) > 5 OR s.avg_acctbal IS NULL
ORDER BY rp.p_brand, rp.p_name DESC;
