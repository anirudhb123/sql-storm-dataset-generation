WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate,
           COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey AND l.l_shipstatus = 'F'
    WHERE o.o_orderdate >= DATE '1994-01-01' AND o.o_orderstatus IN ('O', 'P')
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
),
NegativeBalance AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal < 0
    GROUP BY c.c_custkey, c.c_name
),
HighSpendWithSuppliers AS (
    SELECT fo.o_orderkey, fo.total_revenue, rs.s_name
    FROM FilteredOrders fo
    JOIN RankedSuppliers rs ON fo.o_custkey = (
        SELECT c.c_custkey 
        FROM customer c
        WHERE c.c_acctbal = (
            SELECT MAX(c2.c_acctbal) 
            FROM customer c2
            WHERE c2.c_nationkey = (
                SELECT n.n_nationkey
                FROM nation n
                WHERE n.n_name = 'NATION_1'
            )
        )
    )
    WHERE fo.total_revenue > 0
)
SELECT DISTINCT hs.o_orderkey, hs.total_revenue, hs.s_name
FROM HighSpendWithSuppliers hs
LEFT JOIN NegativeBalance nb ON hs.s_name = nb.c_name
WHERE nb.c_custkey IS NULL 
   OR (hs.total_revenue - (SELECT AVG(total_spent) FROM NegativeBalance) < 100)
ORDER BY hs.total_revenue DESC
LIMIT 10;
