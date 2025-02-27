WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_linenumber) AS total_line_items,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2022-01-01' AND o.o_orderdate < '2023-01-01'
    GROUP BY 
        o.o_orderkey
),
ProductSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_availqty) DESC) AS popularity_rank
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT ns.n_nationkey) AS total_nations,
    SUM(ss.total_parts) AS total_parts_supplied,
    MAX(ss.total_avail_qty) AS max_avail_qty,
    SUM(od.total_order_value) AS total_order_value,
    STRING_AGG(DISTINCT CONCAT('Part: ', p.p_name, ' (Available: ', p.total_available, ')'), '; ') AS parts_overview
FROM 
    region r
LEFT JOIN 
    nation ns ON ns.n_regionkey = r.r_regionkey
LEFT JOIN 
    supplier ss ON ss.s_nationkey = ns.n_nationkey
LEFT JOIN 
    ProductSupplierInfo p ON ss.s_suppkey = p.ps_partkey
LEFT JOIN 
    OrderDetails od ON od.o_orderkey = p.ps_partkey
GROUP BY 
    r.r_regionkey, r.r_name
HAVING 
    COUNT(DISTINCT ns.n_nationkey) > 1 AND 
    SUM(ss.total_parts) IS NOT NULL
ORDER BY 
    total_order_value DESC
LIMIT 10;
