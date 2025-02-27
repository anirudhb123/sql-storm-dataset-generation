WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    
    UNION ALL
    
    SELECT sp.s_suppkey, sp.s_name, sp.s_nationkey, sh.level + 1
    FROM supplier sp
    INNER JOIN SupplierHierarchy sh ON sp.s_suppkey = sh.s_suppkey
    WHERE sp.s_acctbal > sh.level * 10000
),

TotalSales AS (
    SELECT 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_custkey
),

RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
)

SELECT 
    c.c_name AS customer_name,
    SUM(ts.total_spent) AS total_spent,
    sh.level AS supplier_level,
    CASE 
        WHEN ts.total_spent IS NULL THEN 'No purchases'
        WHEN ts.total_spent > 10000 THEN 'High spender'
        ELSE 'Low spender'
    END AS spending_category,
    r.r_name AS region_name
FROM customer c
LEFT JOIN TotalSales ts ON c.c_custkey = ts.o_custkey
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = c.c_nationkey
LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 0
GROUP BY c.c_name, sh.level, r.r_name
ORDER BY total_spent DESC, supplier_level ASC;
