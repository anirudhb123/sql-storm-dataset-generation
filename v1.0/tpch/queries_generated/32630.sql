WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 as level
    FROM supplier s
    WHERE s.s_acctbal > 1000.00

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.level * 500.00
),
OrderSummary AS (
    SELECT o.o_custkey, COUNT(DISTINCT o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent,
           DENSE_RANK() OVER (PARTITION BY o.o_custkey ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
    FROM orders o
    GROUP BY o.o_custkey
),
PartSupplier AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty,
           AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(ps.total_avail_qty, 0) AS total_avail_qty,
    COALESCE(ps.avg_supplycost, 0.00) AS avg_supplycost,
    os.total_orders,
    os.total_spent,
    os.order_rank,
    r.r_name AS supplier_region
FROM part p
LEFT JOIN PartSupplier ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN OrderSummary os ON os.o_custkey IN (
        SELECT c.c_custkey
        FROM customer c
        WHERE c.c_nationkey IN (
            SELECT n.n_nationkey
            FROM nation n
            WHERE n.n_regionkey IN (
                SELECT r.r_regionkey
                FROM region r
                WHERE r.r_name LIKE 'E%'
            )
        )
    )
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN region r ON s.s_nationkey = r.r_regionkey
WHERE p.p_retailprice > (
    SELECT AVG(p2.p_retailprice) FROM part p2
    WHERE p2.p_size > 10
)
ORDER BY total_spent DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
