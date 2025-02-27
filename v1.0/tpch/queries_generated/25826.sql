WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT(s.s_name, ' (', p.p_name, ')') AS supplier_part
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
RegionNations AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        n.n_name,
        n.n_nationkey
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
)
SELECT 
    CONCAT('Supplier: ', sp.supplier_part, ' | Quantity: ', sp.ps_availqty, ' | Cost: ', sp.ps_supplycost, 
           ' | Customer: ', co.c_name, ' | Order: ', co.o_orderkey, ' | Total Price: ', co.o_totalprice, 
           ' | Order Date: ', co.o_orderdate) AS order_details,
    rn.r_name AS region_name
FROM 
    SupplierParts sp
JOIN 
    RegionNations rn ON sp.s_suppkey = rn.n_nationkey
JOIN 
    CustomerOrders co ON co.rn = 1
ORDER BY 
    sp.supp_part, co.o_orderdate DESC;
