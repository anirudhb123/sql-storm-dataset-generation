WITH PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        ps.ps_availqty,
        ps.ps_supplycost,
        s.s_name AS supplier_name,
        s.s_address AS supplier_address,
        s.s_phone AS supplier_phone,
        s.s_acctbal AS supplier_acctbal,
        s.s_comment AS supplier_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_address,
        c.c_phone,
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_comment
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT psd.supplier_name) AS num_suppliers,
    SUM(psd.ps_availqty) AS total_available_quantity,
    AVG(psd.p_retailprice) AS avg_retail_price,
    COUNT(DISTINCT co.o_orderkey) AS total_orders,
    SUM(co.o_totalprice) AS total_order_value
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    PartSupplierDetails psd ON s.s_suppkey = psd.s_supplier_key
LEFT JOIN 
    CustomerOrders co ON psd.p_partkey = co.o_orderkey
GROUP BY 
    r.r_name
ORDER BY 
    total_available_quantity DESC, avg_retail_price DESC;
