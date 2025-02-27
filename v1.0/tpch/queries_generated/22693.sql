WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS supplier_rank,
        SUM(ps.ps_availqty) AS total_available_quantity
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY
        s.s_suppkey, s.s_name, p.p_partkey
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS lineitem_count
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey 
    WHERE 
        o.o_orderstatus = 'F' AND 
        EXTRACT(YEAR FROM o.o_orderdate) = 2023
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
PartSupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(CASE 
        WHEN o.o_orderstatus IS NULL THEN 0 
        ELSE fo.total_revenue 
    END) AS total_revenue_generated,
    STRING_AGG(DISTINCT s.s_name) AS suppliers_names,
    MAX(pi.avg_supply_cost) AS highest_avg_supply_cost,
    MIN(pi.supplier_count) AS min_supplier_count
FROM 
    nation n
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    FilteredOrders fo ON o.o_orderkey = fo.o_orderkey
LEFT JOIN 
    RankedSuppliers s ON fo.o_custkey = s.s_suppkey
JOIN 
    PartSupplierInfo pi ON s.s_suppkey = pi.ps_partkey
WHERE 
    n.n_comment NOT LIKE '%test%' 
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 10 
    AND MAX(pi.avg_supply_cost) <= (SELECT AVG(ps_supplycost) FROM partsupp)
ORDER BY 
    nation_name DESC
FETCH FIRST 10 ROWS ONLY;
