WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal,
           1 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) IS NOT NULL
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
    HAVING COUNT(DISTINCT ps.ps_suppkey) > 1
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
),
CombinedData AS (
    SELECT c.c_name, co.total_spent, pd.p_name, pd.p_retailprice,
           RANK() OVER (PARTITION BY c.c_custkey ORDER BY co.total_spent DESC) AS rank_customer_spending
    FROM CustomerOrders co
    INNER JOIN customer c ON co.c_custkey = c.c_custkey
    CROSS JOIN PartDetails pd
)
SELECT ch.s_name, ch.level, cd.c_name, cd.total_spent, cd.p_name, cd.p_retailprice
FROM SupplierHierarchy ch
FULL OUTER JOIN CombinedData cd ON cd.total_spent IS NOT NULL
WHERE ch.level > 1 AND cd.rank_customer_spending <= 10
ORDER BY ch.s_name, cd.total_spent DESC;
