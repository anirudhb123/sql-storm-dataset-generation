WITH PartSupplierDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        s.s_name AS supplier_name, 
        ps.ps_supplycost, 
        ps.ps_availqty,
        CONCAT('Part ', p.p_name, ' from ', s.s_name) AS detail_description
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
RegionNation AS (
    SELECT 
        r.r_regionkey,
        r.r_name, 
        n.n_name AS nation_name, 
        n.n_comment
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
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        CONCAT(c.c_name, ' placed an order with status ', o.o_orderstatus) AS order_description
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
)
SELECT 
    p.supplier_name, 
    p.detail_description, 
    r.nation_name, 
    r.n_comment, 
    c.order_description
FROM 
    PartSupplierDetails p
JOIN 
    RegionNation r ON p.p_partkey % 5 = r.r_regionkey % 5
JOIN 
    CustomerOrders c ON p.p_partkey % 3 = c.c_custkey % 3
WHERE 
    p.ps_supplycost < 100.00
ORDER BY 
    p.supplier_name, c.o_orderdate DESC;
