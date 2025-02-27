WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        CONCAT(p.p_brand, ' ', p.p_name) AS full_part_name,
        LENGTH(CONCAT(p.p_brand, ' ', p.p_name)) AS name_length,
        LOWER(p.p_comment) AS lower_comment
    FROM 
        part p
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        CONCAT(s.s_name, ' ', n.n_name) AS full_supplier_name,
        LENGTH(CONCAT(s.s_name, ' ', n.n_name)) AS supplier_name_length
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_orderdate,
        c.c_name,
        c.c_mktsegment,
        CONCAT(c.c_name, ' ', c.c_mktsegment) AS full_customer_info,
        LENGTH(CONCAT(c.c_name, ' ', c.c_mktsegment)) AS customer_info_length
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        CONCAT(l.l_returnflag, '|', l.l_linestatus) AS flags,
        LENGTH(CONCAT(l.l_returnflag, '|', l.l_linestatus)) AS flags_length
    FROM 
        lineitem l
)
SELECT 
    pd.full_part_name,
    pd.name_length,
    sd.full_supplier_name,
    sd.supplier_name_length,
    od.full_customer_info,
    od.customer_info_length,
    li.flags,
    li.flags_length
FROM 
    PartDetails pd
JOIN 
    SupplierDetails sd ON pd.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost = (
        SELECT MIN(ps_supplycost) FROM partsupp WHERE ps_partkey = pd.p_partkey))
)
JOIN 
    OrderDetails od ON od.o_orderkey = (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = pd.p_partkey LIMIT 1)
JOIN 
    LineItemDetails li ON li.l_orderkey = od.o_orderkey
ORDER BY 
    pd.name_length DESC, sd.supplier_name_length ASC, od.customer_info_length DESC;
