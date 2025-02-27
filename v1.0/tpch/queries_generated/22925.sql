WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        s.s_acctbal, 
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal IS NOT NULL
),
TopSuppliers AS (
    SELECT 
        r.s_suppkey, 
        r.s_name, 
        r.s_acctbal 
    FROM RankedSuppliers r
    WHERE r.supplier_rank <= 3
),
CustomerSummary AS (
    SELECT 
        c.c_custkey, 
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey
),
FilteredCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        cs.total_spent,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
    FROM customer c
    JOIN CustomerSummary cs ON c.c_custkey = cs.c_custkey
    WHERE cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSummary)
),
JoinData AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        s.s_name AS supplier_name, 
        COUNT(DISTINCT c.c_custkey) AS unique_customers
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    LEFT JOIN FilteredCustomers fc ON s.s_suppkey IN (SELECT s2.s_suppkey FROM TopSuppliers s2 WHERE s2.s_acctbal IS NOT NULL)
    GROUP BY p.p_partkey, p.p_name, s.s_name
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    COALESCE(f.unique_customers, 0) AS unique_customers_count,
    CASE 
        WHEN f.unique_customers > 0 THEN 'Has Customers'
        ELSE 'No Customers'
    END AS customer_status,
    ROUND(AVG(l.l_extendedprice * (1 - l.l_discount)), 2) AS avg_revenue
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN JoinData f ON p.p_partkey = f.p_partkey
WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size BETWEEN 10 AND 20)
GROUP BY p.p_partkey, p.p_name
ORDER BY avg_revenue DESC, p.p_name ASC
LIMIT 10 OFFSET 5;
