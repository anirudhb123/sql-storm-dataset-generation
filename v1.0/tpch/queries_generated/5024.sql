WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey, p.p_name, p.p_brand, p.p_type
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        COUNT(l.l_orderkey) AS line_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice
),
RegionNation AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        n.n_nationkey,
        n.n_name
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
)
SELECT 
    rp.r_name AS region_name,
    sn.n_name AS nation_name,
    sp.s_name AS supplier_name,
    SUM(sp.total_available) AS total_parts_available,
    COUNT(DISTINCT co.o_orderkey) AS total_orders,
    SUM(co.net_revenue) AS total_revenue
FROM 
    SupplierParts sp
JOIN 
    RegionNation rp ON sp.s_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_mfgr = 'Manufacturer#1')
JOIN 
    CustomerOrders co ON co.o_totalprice > 1000
JOIN 
    supplier s ON sp.s_suppkey = s.s_suppkey
JOIN 
    nation sn ON s.s_nationkey = sn.n_nationkey
GROUP BY 
    rp.r_name, sn.n_name, sp.s_name
HAVING 
    SUM(sp.total_available) > 500
ORDER BY 
    total_revenue DESC;
