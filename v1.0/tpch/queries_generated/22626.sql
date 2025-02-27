WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
SignificantParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 50000
)
SELECT 
    r.r_name,
    COALESCE(c.high_value_customers, 0) AS high_value_customers,
    COALESCE(s.rank_suppliers, 0) AS rank_suppliers,
    p.total_value
FROM region r
LEFT JOIN (
    SELECT 
        n.n_regionkey,
        COUNT(DISTINCT c.c_custkey) AS high_value_customers
    FROM nation n
    LEFT JOIN HighValueCustomers c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_regionkey
) c ON r.r_regionkey = c.n_regionkey
LEFT JOIN (
    SELECT 
        n.n_regionkey,
        COUNT(s.s_suppkey) AS rank_suppliers
    FROM nation n
    JOIN RankedSuppliers s ON n.n_nationkey = s.s_nationkey
    WHERE s.rnk <= 3
    GROUP BY n.n_regionkey
) s ON r.r_regionkey = s.n_regionkey
JOIN SignificantParts p ON p.total_value > 0
WHERE p.p_partkey IN (
    SELECT ps.p_partkey 
    FROM partsupp ps 
    WHERE ps.ps_availqty IS NOT NULL AND ps.ps_supplycost > 0
)
ORDER BY r.r_name DESC, p.total_value DESC;
