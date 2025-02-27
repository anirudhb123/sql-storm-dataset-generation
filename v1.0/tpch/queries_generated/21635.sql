WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
PartStats AS (
    SELECT 
        p.p_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM
        part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
NationSummary AS (
    SELECT 
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        MAX(s.s_acctbal) AS max_supplier_balance
    FROM 
        nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN lineitem l ON s.s_suppkey = l.l_suppkey
    GROUP BY n.n_name
)
SELECT 
    ps.p_partkey,
    ps.supplier_count,
    ps.total_avail_qty,
    ps.avg_supply_cost,
    ns.total_revenue,
    ns.max_supplier_balance,
    CASE 
        WHEN ps.supplier_count IS NULL THEN 'No Suppliers'
        ELSE 'Suppliers Exist'
    END AS supplier_registration_status,
    ROW_NUMBER() OVER (PARTITION BY ns.n_name ORDER BY ps.total_avail_qty DESC) AS row_num
FROM 
    PartStats ps
LEFT JOIN NationSummary ns ON ns.total_revenue IS NOT NULL
WHERE 
    (ps.avg_supply_cost > 100 OR ps.total_avail_qty < 500)
    AND EXISTS (
        SELECT 1
        FROM SupplierHierarchy sh
        WHERE sh.s_suppkey = ps.supplier_count
    )
ORDER BY 
    ns.total_revenue DESC NULLS LAST
LIMIT 10 OFFSET 5;
