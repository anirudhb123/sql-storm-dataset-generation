WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type
),
RegionCustomerOrders AS (
    SELECT 
        r.r_name AS region_name,
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY 
        r.r_name, c.c_custkey
),
PerformanceBenchmark AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.total_available_qty,
        rp.total_supply_cost,
        rco.region_name,
        rco.order_count,
        rco.total_spent
    FROM 
        RankedParts rp
    JOIN 
        RegionCustomerOrders rco ON rp.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty = rp.total_available_qty LIMIT 1)
ORDER BY 
    rco.total_spent DESC,
    rp.total_supply_cost ASC
LIMIT 100
)
SELECT * FROM PerformanceBenchmark;
