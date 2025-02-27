WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment,
        1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    
    UNION ALL
    
    SELECT 
        s2.s_suppkey,
        s2.s_name,
        s2.s_acctbal,
        s2.s_comment,
        sh.level + 1
    FROM supplier s2
    JOIN SupplierHierarchy sh ON sh.s_suppkey = s2.s_suppkey
    WHERE sh.level < 5
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_linenumber) AS line_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_tax) AS average_tax
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
FilteredOrders AS (
    SELECT 
        os.o_orderkey,
        os.line_count,
        os.total_revenue,
        os.average_tax,
        ROW_NUMBER() OVER (PARTITION BY os.total_revenue ORDER BY os.line_count DESC) AS rn
    FROM OrderStats os
    WHERE os.total_revenue > 1000
)
SELECT 
    p.p_name,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    COALESCE(AVG(coalesce(s.s_acctbal, 0)), 0) AS average_supplier_balance,
    COUNT(DISTINCT fo.o_orderkey) AS order_count,
    SUM(fo.total_revenue) AS total_order_revenue
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN FilteredOrders fo ON ps.ps_partkey = fo.o_orderkey
LEFT JOIN SupplierHierarchy s ON ps.ps_suppkey = s.s_suppkey
WHERE p.p_size BETWEEN 10 AND 30
GROUP BY p.p_name
HAVING SUM(ps.ps_supplycost) > 5000
ORDER BY total_order_revenue DESC
LIMIT 10;
