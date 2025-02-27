WITH RankedParts AS (
    SELECT 
        p.p_name AS part_name, 
        p.p_mfgr AS manufacturer, 
        p.p_type AS part_type, 
        COUNT(ps.ps_partkey) AS supplier_count, 
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY COUNT(ps.ps_partkey) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_type
)

SELECT 
    rp.part_name,
    rp.manufacturer,
    rp.part_type,
    rp.supplier_count,
    rp.total_avail_qty,
    rp.total_supply_cost,
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey,
    o.o_orderstatus,
    o.o_totalprice,
    o.o_orderdate,
    o.o_orderpriority
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.part_name = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON c.c_nationkey = s.s_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    rp.rank <= 5
AND 
    rp.total_avail_qty > 100
ORDER BY 
    rp.supplier_count DESC, rp.total_supply_cost DESC;
