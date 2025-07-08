WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierStats AS (
    SELECT 
        p.p_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS num_suppliers,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
RegionSales AS (
    SELECT 
        r.r_name,
        SUM(o.o_totalprice) AS region_sales
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY r.r_name
)
SELECT 
    s.s_name,
    COALESCE(c.total_spent, 0) AS customer_spending,
    ps.num_suppliers,
    ps.avg_supplycost,
    rs.region_sales
FROM SupplierHierarchy s
LEFT JOIN CustomerOrders c ON s.s_suppkey = c.c_custkey
JOIN PartSupplierStats ps ON s.s_suppkey = ps.p_partkey
LEFT JOIN RegionSales rs ON rs.region_sales > 5000
WHERE s.level = 1 AND (c.total_spent IS NULL OR c.total_spent > 1000)
ORDER BY s.s_name, rs.region_sales DESC;
