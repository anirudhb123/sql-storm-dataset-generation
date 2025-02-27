WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS lvl
    FROM supplier
    WHERE s_suppkey IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.lvl + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.lvl < 5
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS customer_count
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY o.o_orderkey
),
RegionSales AS (
    SELECT 
        r.r_name,
        SUM(os.total_revenue) AS total_region_revenue
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN OrderSummary os ON c.c_custkey = os.o_orderkey
    GROUP BY r.r_name
),
TopSuppliers AS (
    SELECT 
        s.s_name,
        s.s_acctbal,
        RANK() OVER (ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
)
SELECT 
    r.r_name AS region_name,
    COALESCE(rs.total_region_revenue, 0) AS total_revenue,
    ts.s_name AS top_supplier,
    ts.s_acctbal AS supplier_balance
FROM RegionSales rs
FULL OUTER JOIN TopSuppliers ts ON ts.s_acctbal > 100000
JOIN region r ON r.r_name = rs.r_name
WHERE r.r_comment LIKE '%important%'
ORDER BY region_name, supplier_balance DESC;
