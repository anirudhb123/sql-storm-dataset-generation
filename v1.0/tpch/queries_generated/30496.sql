WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
),
MinMaxPrices AS (
    SELECT 
        p.p_partkey, 
        MIN(ps.ps_supplycost) AS min_supplycost, 
        MAX(ps.ps_supplycost) AS max_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
OrderStatistics AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
    GROUP BY o.o_orderkey
),
TopSuppliers AS (
    SELECT 
        sh.s_nationkey, 
        COUNT(DISTINCT sh.s_suppkey) AS supplier_count
    FROM SupplierHierarchy sh
    GROUP BY sh.s_nationkey
),
NationPerformance AS (
    SELECT 
        n.n_name,
        COALESCE(MAX(os.total_revenue), 0) AS max_revenue,
        SUM(IF(os.item_count > 0, os.item_count, NULL)) AS total_items
    FROM nation n
    LEFT JOIN OrderStatistics os ON n.n_nationkey = (SELECT DISTINCT s_nationkey FROM supplier WHERE s_suppkey = os.o_orderkey)
    GROUP BY n.n_name
)
SELECT 
    n.n_name AS nation_name,
    n.r_name AS region_name,
    th.supplier_count,
    np.max_revenue,
    np.total_items,
    CASE 
        WHEN np.max_revenue IS NULL THEN 'No Revenue' 
        ELSE 'Revenue Achieved' 
    END AS revenue_status
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN TopSuppliers th ON n.n_nationkey = th.s_nationkey
LEFT JOIN NationPerformance np ON n.n_nationkey = np.n_nationkey
ORDER BY np.max_revenue DESC, n.n_name;
