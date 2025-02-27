WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS hierarchy_level
    FROM supplier s
    WHERE s.s_acctbal > 5000.00
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.hierarchy_level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
    WHERE s.s_acctbal BETWEEN 3000.00 AND 5000.00
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_suppkey) AS unique_suppliers
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY o.o_orderkey
),
NationSummary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(c.c_acctbal) AS total_acctbal
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
PartSupplier AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    ns.n_name,
    ns.customer_count,
    ns.total_acctbal,
    ps.p_name,
    ps.supplier_count,
    ps.avg_supplycost,
    COALESCE(oh.total_revenue, 0) AS total_revenue,
    ROW_NUMBER() OVER (PARTITION BY ns.n_name ORDER BY ps.avg_supplycost DESC) AS revenue_rank
FROM NationSummary ns
JOIN PartSupplier ps ON ns.n_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'N%')
LEFT JOIN OrderSummary oh ON oh.unique_suppliers = ps.supplier_count
WHERE ns.customer_count > 10
ORDER BY ns.n_name, ps.avg_supplycost DESC;