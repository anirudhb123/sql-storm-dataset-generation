WITH SupplierDetails AS (
    SELECT 
        s.s_name AS supplier_name,
        s.s_address AS supplier_address,
        s.s_phone AS supplier_phone,
        n.n_name AS nation_name,
        n.n_comment AS nation_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),

PartDetails AS (
    SELECT 
        p.p_name AS part_name,
        p.p_mfgr AS manufacturer,
        p.p_brand AS brand,
        p.p_type AS part_type,
        p.p_size AS size,
        p.p_container AS container,
        p.p_retailprice AS retail_price,
        p.p_comment AS part_comment
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT ps.ps_availqty FROM partsupp ps WHERE ps.ps_supplycost > 100.00)
),

OrderDetails AS (
    SELECT 
        o.o_orderkey AS order_key,
        o.o_orderstatus AS order_status,
        o.o_totalprice AS total_price,
        o.o_orderdate AS order_date,
        o.o_comment AS order_comment,
        SUBSTRING(o.o_comment, 1, 15) AS short_order_comment
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2023-01-01' AND o.o_orderdate <= '2023-12-31'
)

SELECT 
    sd.supplier_name,
    pd.part_name,
    od.order_key,
    CONCAT('Order ', od.order_key, ' for part ', pd.part_name) AS order_summary,
    pd.retail_price,
    pd.part_comment,
    sd.nation_name,
    sd.supplier_phone
FROM 
    SupplierDetails sd
JOIN 
    lineitem l ON sd.supplier_name = l.l_suppkey
JOIN 
    PartDetails pd ON l.l_partkey = pd.part_name
JOIN 
    OrderDetails od ON l.l_orderkey = od.order_key
WHERE 
    od.total_price > 500.00
ORDER BY 
    sd.nation_name, pd.brand, od.order_date DESC;
