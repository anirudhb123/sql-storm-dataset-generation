WITH part_details AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        TRIM(UPPER(p.p_comment)) AS formatted_comment
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100)
),
supplier_regions AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        s.s_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.s_acctbal > 50000
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(l.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
final_benchmark AS (
    SELECT 
        pd.p_name,
        sr.nation_name,
        os.o_orderstatus,
        os.total_sales,
        os.line_item_count,
        pd.formatted_comment
    FROM 
        part_details pd
    JOIN 
        partsupp ps ON pd.p_partkey = ps.ps_partkey
    JOIN 
        supplier_regions sr ON ps.ps_suppkey = sr.s_suppkey
    JOIN 
        order_summary os ON sr.s_suppkey IN (SELECT ps_suppkey FROM partsupp WHERE ps_partkey = pd.p_partkey)
    WHERE 
        pd.p_size < 20
)
SELECT 
    p_name, 
    nation_name, 
    o_orderstatus, 
    total_sales, 
    line_item_count, 
    formatted_comment
FROM 
    final_benchmark
ORDER BY 
    total_sales DESC, 
    line_item_count ASC;