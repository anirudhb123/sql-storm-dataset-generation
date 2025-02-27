WITH SupplierPartDetails AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        s.s_comment AS supplier_comment,
        CONCAT(p.p_brand, ' ', p.p_mfgr) AS brand_mfgr,
        CONCAT('Part: ', p.p_name, ', Supplied by: ', s.s_name, ' (', s.s_nationkey, ')') AS part_supplier_info
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrderDetails AS (
    SELECT 
        c.c_name AS customer_name,
        c.c_mktsegment AS market_segment,
        o.o_orderkey AS order_id,
        DATE_FORMAT(o.o_orderdate, '%Y-%m-%d') AS order_date,
        CONCAT('Customer: ', c.c_name, ', Order ID: ', o.o_orderkey) AS order_customer_info
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
),
RegionSupplierCount AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    r.r_name AS region_name,
    rsc.supplier_count,
    spd.supplier_name,
    spd.part_name,
    spd.brand_mfgr,
    spd.part_supplier_info,
    cod.customer_name,
    cod.market_segment,
    cod.order_id,
    cod.order_date,
    cod.order_customer_info
FROM 
    region r
JOIN 
    RegionSupplierCount rsc ON r.r_regionkey = rsc.nation_name
JOIN 
    SupplierPartDetails spd ON spd.supplier_name LIKE '% Ltd%'
JOIN 
    CustomerOrderDetails cod ON cod.market_segment = 'Retail'
ORDER BY 
    r.r_name, spd.supplier_name, cod.order_date DESC;
