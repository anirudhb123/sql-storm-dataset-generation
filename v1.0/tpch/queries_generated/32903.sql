WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_acctbal, c_nationkey, 0 AS level
    FROM customer
    WHERE c_custkey = (SELECT MIN(c_custkey) FROM customer)
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_custkey > ch.c_custkey
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) as rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
AggregatedSales AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
),
FinalResults AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(SUM(ps.ps_availqty), 0) AS total_available_qty,
        COALESCE(SUM(l.total_revenue), 0) AS total_revenue,
        RANK() OVER (ORDER BY COALESCE(SUM(l.total_revenue), 0) DESC) AS revenue_rank
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN AggregatedSales l ON l.l_orderkey = ps.ps_suppkey 
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    ch.c_name,
    ch.level,
    p.p_name,
    fr.total_available_qty,
    fr.total_revenue,
    rs.s_name AS top_supplier,
    rs.rank AS supplier_rank
FROM CustomerHierarchy ch
JOIN FinalResults fr ON fr.total_revenue > ch.c_acctbal
LEFT JOIN RankedSuppliers rs ON fr.total_revenue > 100000
WHERE fr.total_available_qty IS NOT NULL
ORDER BY ch.level, fr.total_revenue DESC;
