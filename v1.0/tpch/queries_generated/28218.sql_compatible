
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        s.s_comment,
        CONCAT(s.s_name, ' - ', s.s_address) AS supplier_full_info
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_container,
        CONCAT(p.p_name, ' (', p.p_brand, ')') AS part_full_info
    FROM 
        part p
),
OrderLineItem AS (
    SELECT 
        o.o_orderkey,
        ol.l_partkey,
        ol.l_quantity,
        ol.l_extendedprice,
        ol.l_discount,
        ol.l_tax,
        ol.l_returnflag,
        ol.l_linestatus,
        CONCAT(o.o_orderkey, '-', ol.l_linenumber) AS order_line_info
    FROM 
        orders o
    JOIN 
        lineitem ol ON o.o_orderkey = ol.l_orderkey
)
SELECT 
    sd.supplier_full_info,
    pd.part_full_info,
    SUM(oli.l_quantity) AS total_quantity,
    SUM(oli.l_extendedprice) AS total_sales,
    AVG(oli.l_discount) AS avg_discount,
    STRING_AGG(oli.order_line_info, ', ') AS detailed_order_lines
FROM 
    SupplierDetails sd
JOIN 
    partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN 
    PartDetails pd ON ps.ps_partkey = pd.p_partkey
JOIN 
    OrderLineItem oli ON oli.l_partkey = pd.p_partkey
GROUP BY 
    sd.supplier_full_info, pd.part_full_info
ORDER BY 
    total_sales DESC;
