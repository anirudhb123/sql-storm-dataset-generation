WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal)
        FROM supplier s2
        JOIN nation n2 ON s2.s_nationkey = n2.n_nationkey
        WHERE n2.n_regionkey = n.n_regionkey
    )
),
OrderStats AS (
    SELECT 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_custkey
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(os.total_spent), 0) AS total_spent_by_customer,
        COALESCE(SUM(os.total_orders), 0) AS total_orders_by_customer
    FROM customer c
    LEFT JOIN OrderStats os ON c.c_custkey = os.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    cs.c_name,
    cs.total_spent_by_customer,
    cs.total_orders_by_customer,
    rs.s_name AS top_supplier,
    rs.s_acctbal
FROM CustomerStats cs
LEFT JOIN RankedSuppliers rs ON cs.total_spent_by_customer > 10000 AND rs.rank = 1
WHERE cs.total_orders_by_customer > 0
ORDER BY cs.total_spent_by_customer DESC 
LIMIT 10;
