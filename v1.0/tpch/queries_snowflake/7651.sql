WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS supplier_nation,
        r.r_name AS supplier_region,
        s.s_acctbal,
        s.s_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
), 
OrderStatistics AS (
    SELECT 
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_revenue,
        AVG(o.o_totalprice) AS avg_order_value,
        o.o_orderpriority
    FROM 
        orders o
    GROUP BY 
        o.o_orderpriority
)
SELECT 
    rp.p_name,
    rp.p_mfgr,
    rp.p_brand,
    rp.p_size,
    rp.total_supply_cost,
    sd.s_name,
    sd.supplier_nation,
    sd.supplier_region,
    os.total_orders,
    os.total_revenue,
    os.avg_order_value,
    os.o_orderpriority
FROM 
    RankedParts rp
JOIN 
    SupplierDetails sd ON sd.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = rp.p_partkey ORDER BY ps.ps_supplycost LIMIT 1)
JOIN 
    OrderStatistics os ON os.o_orderpriority = CASE 
        WHEN rp.total_supply_cost > 1000 THEN 'HIGH'
        WHEN rp.total_supply_cost BETWEEN 500 AND 1000 THEN 'MEDIUM'
        ELSE 'LOW'
    END
WHERE 
    rp.p_size > 20
ORDER BY 
    rp.total_supply_cost DESC, 
    os.total_orders DESC;
