WITH SupplierRevenue AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * l.l_quantity) AS total_revenue
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
    GROUP BY s.s_suppkey, s.s_name
), 
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        COUNT(l.l_orderkey) AS order_count
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT
    s.s_name, 
    s.total_revenue, 
    c.c_name, 
    c.total_spent, 
    p.p_name, 
    pd.order_count
FROM SupplierRevenue s
FULL OUTER JOIN HighValueCustomers c ON s.s_suppkey = c.c_custkey
LEFT JOIN PartDetails pd ON s.s_suppkey = pd.p_partkey
WHERE s.total_revenue IS NOT NULL OR c.total_spent IS NOT NULL
ORDER BY 
    COALESCE(s.total_revenue, 0) DESC,
    COALESCE(c.total_spent, 0) DESC;
