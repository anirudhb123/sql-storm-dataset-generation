WITH RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) as part_rank
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
),
SupplierAgg AS (
    SELECT s.s_nationkey, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(s.s_acctbal) AS total_acctbal
    FROM supplier s
    GROUP BY s.s_nationkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name,
           SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F' OR o.o_orderdate > DATEADD(year, -1, GETDATE())
    GROUP BY c.c_custkey, c.c_name
)
SELECT r.r_name, 
       COUNT(DISTINCT c.c_custkey) AS num_customers,
       SUM(COALESCE(sa.total_acctbal, 0)) AS total_supplier_acctbal,
       AVG(co.total_spent) AS avg_customer_spent,
       MAX(P.p_retailprice) AS max_part_price,
       STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierAgg sa ON n.n_nationkey = sa.s_nationkey
LEFT JOIN CustomerOrders co ON n.n_nationkey = (SELECT n2.n_nationkey FROM customer c2 JOIN supplier s2 ON c2.c_nationkey = s2.s_nationkey WHERE c2.c_custkey = co.c_custkey)
LEFT JOIN RankedParts p ON p.part_rank <= 3
WHERE r.r_name IS NOT NULL AND n.n_name IS NOT NULL
GROUP BY r.r_name
HAVING COUNT(DISTINCT co.c_custkey) > 5 AND SUM(sa.supplier_count) > 0
ORDER BY num_customers DESC, total_supplier_acctbal DESC;
