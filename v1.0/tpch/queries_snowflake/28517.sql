
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        n.n_name AS nation_name, 
        r.r_name AS region_name, 
        LENGTH(s.s_comment) AS comment_length
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
        p.p_size, 
        p.p_container, 
        p.p_retailprice, 
        LENGTH(p.p_comment) AS comment_length
    FROM 
        part p
),
OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        COUNT(l.l_orderkey) AS line_item_count, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        MIN(l.l_shipdate) AS first_ship_date,
        MAX(l.l_shipdate) AS last_ship_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, 
        o.o_custkey
)
SELECT 
    sd.s_name AS supplier_name,
    pd.p_name AS part_name,
    os.total_revenue,
    os.first_ship_date,
    os.last_ship_date,
    sd.comment_length AS supplier_comment_length,
    pd.comment_length AS part_comment_length
FROM 
    SupplierDetails sd
JOIN 
    partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN 
    PartDetails pd ON ps.ps_partkey = pd.p_partkey
JOIN 
    OrderSummary os ON os.o_orderkey = (
        SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = sd.s_suppkey LIMIT 1
    )
WHERE 
    sd.comment_length > 50 AND 
    pd.comment_length < 20
ORDER BY 
    os.total_revenue DESC, 
    sd.s_name;
