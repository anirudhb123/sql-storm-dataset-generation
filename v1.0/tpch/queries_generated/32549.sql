WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal <= 5000 
),

PartSummary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),

HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_orderstatus = 'O' AND o.o_totalprice > 10000
)

SELECT 
    p.p_name,
    ps.total_cost,
    sh.s_name AS supplier_name,
    o.o_orderkey,
    o.o_totalprice,
    COALESCE(NULLIF(o.o_orderstatus, 'F'), 'Pending') AS status,
    RANK() OVER (ORDER BY ps.total_cost DESC) AS cost_rank,
    CASE 
        WHEN o.o_totalprice IS NULL THEN 'No Orders' 
        ELSE 'Orders Exist' 
    END AS order_status
FROM 
    PartSummary ps 
LEFT JOIN 
    SupplierHierarchy sh ON sh.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_nationkey = sh.s_nationkey LIMIT 1)
LEFT JOIN 
    lineitem l ON ps.p_partkey = l.l_partkey
LEFT JOIN 
    HighValueOrders o ON l.l_orderkey = o.o_orderkey
WHERE 
    ps.total_cost > 100000
ORDER BY 
    ps.total_cost DESC, supplier_name;
