WITH part_details AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        p.p_comment,
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT(p.p_name, ' - ', p.p_comment) AS full_description
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        STRING_AGG(o.o_comment, '; ') AS comments_summary
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
supplier_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name AS region_name,
        STRING_AGG(DISTINCT sua.p_name, ', ') AS supplied_parts
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part sua ON ps.ps_partkey = sua.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, r.r_name
)
SELECT 
    pd.full_description,
    co.c_name,
    co.total_spent,
    si.region_name,
    si.supplied_parts
FROM 
    part_details pd
JOIN 
    customer_orders co ON pd.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost < 100)
JOIN 
    supplier_info si ON si.supplied_parts LIKE '%' || pd.p_name || '%'
ORDER BY 
    co.total_spent DESC, pd.p_retailprice DESC
LIMIT 10;
