WITH CombinedInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        s.s_name AS supplier_name,
        c.c_name AS customer_name,
        o.o_orderdate,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        r.r_name AS region_name,
        n.n_name AS nation_name
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    CONCAT('Part Name: ', p_name, ', Supplier: ', supplier_name, ', Customer: ', customer_name, 
           ', Order Date: ', TO_CHAR(o_orderdate, 'YYYY-MM-DD'), 
           ', Total Price: ', FORMAT(o_totalprice, 2), 
           ', Quantity: ', FORMAT(SUM(l_quantity), 2), 
           ', Discount: ', FORMAT(SUM(l_discount * l_extendedprice), 2), 
           ', Tax: ', FORMAT(SUM(l_tax * l_extendedprice), 2), 
           ', Region: ', region_name, 
           ', Nation: ', nation_name) AS details
FROM 
    CombinedInfo
GROUP BY 
    p_partkey, p_name, supplier_name, customer_name, o_orderdate
ORDER BY 
    o_orderdate DESC, supplier_name;
