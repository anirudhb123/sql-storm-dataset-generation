WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, COUNT(ps.ps_partkey) AS part_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
    HAVING COUNT(ps.ps_partkey) > 0
    UNION ALL
    SELECT sc.s_suppkey, sc.s_name, sc.s_acctbal, sc.part_count + 1
    FROM SupplyChain sc
    JOIN supplier s ON sc.s_suppkey = s.s_suppkey
    WHERE sc.part_count < 10
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'P')
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 5000
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           DENSE_RANK() OVER (ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
)
SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_retailprice,
       sc.part_count,
       COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
       COALESCE(hvc.total_spent, 0) AS total_spent,
       RANK() OVER (ORDER BY p.p_retailprice DESC) AS retail_price_rank
FROM part p
FULL OUTER JOIN SupplyChain sc ON p.p_partkey = sc.s_suppkey
LEFT JOIN HighValueCustomers hvc ON hvc.c_custkey = sc.s_suppkey
JOIN RankedSuppliers r ON r.s_suppkey = sc.s_suppkey
WHERE (p.p_size > 10 OR (p.p_container IS NULL AND p.p_retailprice < 100))
  AND (EXISTS (SELECT 1 FROM lineitem l WHERE l.l_partkey = p.p_partkey AND l.l_quantity > 100)
       OR NOT EXISTS (SELECT 1 FROM lineitem l WHERE l.l_partkey = p.p_partkey))
ORDER BY retail_price_rank, sc.part_count DESC;
