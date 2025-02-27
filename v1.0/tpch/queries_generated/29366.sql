WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY SUM(ps.ps_availqty) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(*) AS num_supply_parts,
        RANK() OVER (ORDER BY COUNT(*) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        COUNT(*) > 1 
),
RegionDetails AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_name) AS nation_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_mfgr,
    rp.total_avail_qty,
    rp.avg_supply_cost,
    ts.s_name AS top_supplier_name,
    ts.num_supply_parts,
    rd.r_name AS region_name,
    rd.nation_count
FROM 
    RankedParts rp
JOIN 
    TopSuppliers ts ON rp.p_mfgr = (SELECT p_mfgr FROM part WHERE p_partkey = rp.p_partkey LIMIT 1)
JOIN 
    RegionDetails rd ON rd.nation_count > 2
WHERE 
    rp.rank = 1
ORDER BY 
    rp.total_avail_qty DESC, ts.num_supply_parts DESC;
