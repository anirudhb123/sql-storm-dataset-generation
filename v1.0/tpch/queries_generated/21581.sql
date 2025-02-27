WITH RECURSIVE SupplierRates AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
    HAVING COUNT(DISTINCT ps.ps_partkey) > 0
    UNION ALL
    SELECT sr.s_suppkey, sr.s_name, sr.s_acctbal * 1.1, sr.part_count + 1
    FROM SupplierRates sr
    WHERE sr.part_count < 10
),
TotalRevenue AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N' 
    GROUP BY c.c_custkey
    HAVING total_revenue > (
        SELECT AVG(total_revenue)
        FROM (
            SELECT SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
            FROM customer c2
            JOIN orders o2 ON c2.c_custkey = o2.o_custkey
            JOIN lineitem l2 ON o2.o_orderkey = l2.l_orderkey
            WHERE l2.l_returnflag = 'N'
            GROUP BY c2.c_custkey
        ) subquery
    )
),
SupplierInfo AS (
    SELECT s.s_name, 
           sr.part_count, 
           ROUND((s.s_acctbal / NULLIF(sr.part_count, 0)), 2) AS avg_acct_bal_per_part,
           CASE WHEN sr.part_count > 5 THEN 'High' ELSE 'Low' END AS supplier_category
    FROM supplier s 
    JOIN SupplierRates sr ON s.s_suppkey = sr.s_suppkey
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, tr.total_revenue
    FROM customer c
    JOIN TotalRevenue tr ON c.c_custkey = tr.c_custkey
    WHERE c.c_name IS NOT NULL
    ORDER BY tr.total_revenue DESC
    LIMIT 10
)
SELECT 
    tc.c_name, 
    si.s_name, 
    si.avg_acct_bal_per_part,
    si.supplier_category,
    COALESCE(SUM(l.l_extendedprice), 0) AS total_spent
FROM TopCustomers tc
LEFT JOIN lineitem l ON l.l_orderkey IN (
    SELECT o.o_orderkey 
    FROM orders o WHERE o.o_custkey = tc.c_custkey
)
LEFT JOIN SupplierInfo si ON l.l_suppkey = si.s_suppkey
GROUP BY tc.c_name, si.s_name, si.avg_acct_bal_per_part, si.supplier_category
ORDER BY total_spent DESC, tc.c_name;
