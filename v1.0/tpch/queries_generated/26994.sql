WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        n.n_name AS nation_name, 
        r.r_name AS region_name, 
        CONCAT(s.s_name, ' from ', n.n_name, ', ', r.r_name) AS supplier_location 
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
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        p.p_retailprice, 
        p.p_comment,
        CONCAT(p.p_brand, ' ', p.p_type, ' ', p.p_name) AS custom_description
    FROM 
        part p
),
OrderLineItem AS (
    SELECT 
        l.l_orderkey, 
        l.l_partkey, 
        l.l_quantity, 
        l.l_extendedprice, 
        l.l_discount, 
        l.l_returnflag, 
        l.l_linestatus, 
        pd.custom_description,
        sd.supplier_location,
        l.l_shipdate
    FROM 
        lineitem l 
    JOIN 
        PartDetails pd ON l.l_partkey = pd.p_partkey 
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey 
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey 
    JOIN 
        SupplierDetails sd ON s.s_suppkey = sd.s_suppkey
)
SELECT 
    ol.l_orderkey,
    COUNT(DISTINCT ol.l_partkey) AS unique_parts_count,
    SUM(ol.l_extendedprice * (1 - ol.l_discount)) AS total_revenue,
    STRING_AGG(DISTINCT ol.custom_description, ', ') AS part_descriptions,
    MAX(ol.l_shipdate) AS latest_ship_date
FROM 
    OrderLineItem ol
WHERE 
    ol.l_returnflag = 'N'
GROUP BY 
    ol.l_orderkey
ORDER BY 
    total_revenue DESC 
LIMIT 10;
