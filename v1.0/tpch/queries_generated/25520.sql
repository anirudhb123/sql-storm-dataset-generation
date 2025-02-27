WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        COUNT(p.ps_partkey) AS total_parts,
        SUM(p.ps_supplycost) AS total_supplycost,
        SUM(CASE WHEN p.ps_availqty < 100 THEN 1 ELSE 0 END) AS low_stock_parts
    FROM 
        supplier s
    JOIN 
        partsupp p ON s.s_suppkey = p.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
RegionAnalysis AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS number_of_nations,
        SUM(ss.total_parts) AS total_parts_supplied
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        SupplierStats ss ON ss.s_nationkey = n.n_nationkey
    GROUP BY 
        r.r_name
)
SELECT 
    rp.p_brand,
    rp.p_name,
    cs.c_name,
    cs.total_spent,
    ra.number_of_nations,
    ra.total_parts_supplied,
    rp.rank
FROM 
    RankedParts rp
JOIN 
    CustomerOrders cs ON cs.order_count > 0
JOIN 
    RegionAnalysis ra ON ra.total_parts_supplied > 1000
WHERE 
    rp.rank <= 5
ORDER BY 
    rp.p_brand, cs.total_spent DESC;
