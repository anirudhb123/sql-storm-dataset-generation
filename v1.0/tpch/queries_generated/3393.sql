WITH SupplierAverage AS (
    SELECT s_nationkey,
           AVG(s_acctbal) AS avg_acctbal,
           COUNT(*) AS num_suppliers
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    GROUP BY s_nationkey
),
TopParts AS (
    SELECT p_partkey,
           p_name,
           SUM(ps_supplycost * ps_availqty) AS total_cost
    FROM partsupp
    JOIN part ON ps_partkey = p_partkey
    GROUP BY p_partkey, p_name
    HAVING SUM(ps_supplycost * ps_availqty) > (
        SELECT AVG(ps_supplycost * ps_availqty)
        FROM partsupp
    )
),
OrderDetails AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
NationMaxOrders AS (
    SELECT n.n_name,
           COUNT(o.o_orderkey) AS num_orders
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_name
    HAVING COUNT(o.o_orderkey) = (
        SELECT MAX(order_count)
        FROM (
            SELECT COUNT(o1.o_orderkey) AS order_count
            FROM nation n1
            LEFT JOIN customer c1 ON n1.n_nationkey = c1.c_nationkey
            LEFT JOIN orders o1 ON c1.c_custkey = o1.o_custkey
            GROUP BY n1.n_nationkey
        ) AS order_counts
    )
)
SELECT n.n_name,
       COALESCE(sa.avg_acctbal, 0) AS average_balance,
       tp.p_name,
       od.total_revenue,
       nm.num_orders
FROM NationMaxOrders nm
JOIN nation n ON n.n_name = nm.n_name
LEFT JOIN SupplierAverage sa ON sa.s_nationkey = n.n_nationkey
LEFT JOIN TopParts tp ON tp.p_partkey IN (
    SELECT ps_partkey
    FROM partsupp
    WHERE ps_supplycost = (
        SELECT MIN(ps_supplycost)
        FROM partsupp
        WHERE ps_partkey = tp.p_partkey
    )
)
JOIN OrderDetails od ON od.o_orderkey IN (
    SELECT o_orderkey
    FROM orders
    WHERE o_orderdate >= '2022-01-01' -- Complicated predicate
)
ORDER BY od.total_revenue DESC, n.n_name;
