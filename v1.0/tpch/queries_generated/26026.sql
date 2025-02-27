WITH SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_container,
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' in ', p.p_container, ' containers') AS SupplierPartComment
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), 
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        CONCAT(c.c_name, ' placed an order (OrderID: ', o.o_orderkey, ') on ', o.o_orderdate) AS CustomerOrderComment
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
), 
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        CONCAT('Line Item for Order ', l.l_orderkey, ': Quantity ', l.l_quantity, ', Extended Price ', l.l_extendedprice) AS LineItemComment
    FROM 
        lineitem l
)
SELECT 
    spd.s_name AS SupplierName,
    spd.p_name AS PartName,
    spd.SupplierPartComment,
    cod.c_name AS CustomerName,
    cod.CustomerOrderComment,
    lid.LineItemComment,
    lid.l_quantity,
    lid.l_extendedprice,
    lid.l_discount,
    lid.l_tax
FROM 
    SupplierPartDetails spd
JOIN 
    LineItemDetails lid ON spd.p_partkey = lid.l_partkey
JOIN 
    CustomerOrderDetails cod ON lid.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cod.c_custkey)
ORDER BY 
    spd.s_name, cod.c_name, lid.l_orderkey;
