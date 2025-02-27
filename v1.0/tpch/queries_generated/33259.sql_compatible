
WITH RECURSIVE PartSupplierHierarchy AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        ps.ps_availqty,
        ps.ps_supplycost,
        1 AS level
    FROM partsupp ps
    WHERE ps.ps_availqty > 0
    
    UNION ALL
    
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        ps.ps_availqty,
        ps.ps_supplycost,
        psh.level + 1
    FROM partsupp ps
    INNER JOIN PartSupplierHierarchy psh ON psh.ps_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > psh.ps_availqty
),
TotalPartCost AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_cost
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY p.p_partkey
),
ActiveSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
    GROUP BY s.s_suppkey, s.s_name
),
SupplierPerformance AS (
    SELECT 
        a.s_suppkey,
        a.s_name,
        COALESCE(p.total_cost, 0) AS total_part_cost,
        a.total_avail_qty,
        RANK() OVER (PARTITION BY a.s_suppkey ORDER BY COALESCE(p.total_cost, 0) DESC) AS Rank
    FROM ActiveSuppliers a
    LEFT JOIN TotalPartCost p ON a.s_suppkey = p.p_partkey
)
SELECT 
    sp.s_suppkey,
    sp.s_name,
    sp.total_part_cost,
    sp.total_avail_qty,
    sp.Rank,
    CASE 
        WHEN sp.total_part_cost > 10000 THEN 'High Value Supplier'
        WHEN sp.total_part_cost > 5000 THEN 'Medium Value Supplier'
        ELSE 'Low Value Supplier'
    END AS SupplierType,
    COALESCE(r.r_name, 'Unknown') AS region_name
FROM SupplierPerformance sp
LEFT JOIN supplier s ON sp.s_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE sp.total_avail_qty IS NOT NULL
ORDER BY sp.total_part_cost DESC, sp.s_name;
