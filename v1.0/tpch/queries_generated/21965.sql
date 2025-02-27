WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rank,
        COUNT(ps.ps_supplycost) as supply_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
), 
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) as total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    rs.s_name AS supplier_name,
    COALESCE(hvc.total_spent, 0) AS customer_spending,
    CASE 
        WHEN hvc.total_spent IS NULL THEN 'No Purchases'
        ELSE 'Purchases Above Threshold'
    END AS customer_status,
    SUM(l.l_quantity * l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY p.p_partkey) AS total_revenue,
    RANK() OVER (ORDER BY SUM(l.l_quantity * l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN RankedSuppliers rs ON l.l_suppkey = rs.s_suppkey AND rs.rank <= 3
LEFT JOIN HighValueCustomers hvc ON hvc.c_custkey = (
    SELECT o.o_custkey 
    FROM orders o 
    WHERE o.o_orderkey IN (
        SELECT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_partkey = p.p_partkey
    ) 
    LIMIT 1
)
WHERE p.p_size > 20
AND p.p_retailprice < (
    SELECT AVG(p_inner.p_retailprice)
    FROM part p_inner
    WHERE p_inner.p_type = p.p_type
)
ORDER BY total_revenue DESC
LIMIT 100;
