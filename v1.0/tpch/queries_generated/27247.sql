WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        CONCAT('Manufacturer: ', p.p_mfgr, ', Brand: ', p.p_brand, ' (', p.p_type, ') - Price: $', FORMAT(p.p_retailprice, 2), ' | ', p.p_comment) AS detailed_description
    FROM 
        part p
), SupplierCountry AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        CONCAT('Supplier: ', s.s_name, ', Address: ', s.s_address, ', Phone: ', s.s_phone) AS supplier_info
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), OrderSummary AS (
    SELECT 
        o.o_orderkey,
        c.c_name AS customer_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sale,
        COUNT(l.l_orderkey) AS total_items,
        o.o_orderdate,
        CONCAT('Order: ', o.o_orderkey, ', Customer: ', c.c_name, ', Date: ', FORMAT(o.o_orderdate, 'yyyy-MM-dd'), ' - Total Sale: $', FORMAT(SUM(l.l_extendedprice * (1 - l.l_discount)), 2)) AS order_info
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_name, o.o_orderdate
)
SELECT 
    p.p_partkey,
    p.detailed_description,
    s.supplier_info,
    o.order_info
FROM 
    PartDetails p
JOIN 
    SupplierCountry s ON p.p_partkey IN (SELECT ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
JOIN 
    OrderSummary o ON p.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O'))
ORDER BY 
    p.p_partkey, s.s_suppkey;
