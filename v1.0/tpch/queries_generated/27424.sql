WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Available: ', ps.ps_availqty) AS detail
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
RegionNations AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        CONCAT('Region: ', r.r_name, ', Nation: ', n.n_name) AS region_detail
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
),
CustomerOrders AS (
    SELECT 
        c.c_name AS customer_name,
        o.o_orderkey AS order_number,
        CONCAT('Customer: ', c.c_name, ', Order Number: ', o.o_orderkey) AS order_detail
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
)
SELECT 
    sp.supplier_name,
    sp.part_name,
    sp.available_quantity,
    rn.region_name,
    rn.nation_name,
    co.customer_name,
    co.order_number,
    sp.detail AS supplier_part_detail,
    rn.region_detail,
    co.order_detail
FROM 
    SupplierParts sp
JOIN 
    RegionNations rn ON sp.available_quantity > 0
JOIN 
    CustomerOrders co ON rn.nation_name = (
        SELECT n.n_name
        FROM nation n
        JOIN supplier s ON s.s_nationkey = n.n_nationkey
        WHERE s.s_name = sp.supplier_name
        LIMIT 1
    )
WHERE 
    sp.available_quantity > 100
ORDER BY 
    sp.available_quantity DESC, rn.region_name, co.customer_name;
