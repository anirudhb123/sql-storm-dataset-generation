WITH ranked_suppliers AS (
    SELECT 
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
top_suppliers AS (
    SELECT 
        r.r_name AS region_name,
        rs.nation_name,
        rs.s_name,
        rs.s_acctbal
    FROM 
        ranked_suppliers rs
    JOIN 
        nation n ON rs.nation_name = n.n_name
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 5
),
processed_parts AS (
    SELECT 
        p.p_name,
        p.p_type,
        LOWER(p.p_comment) AS processed_comment,
        TRIM(REPLACE(REPLACE(REPLACE(p.p_comment, ' ', '_'), '.', ''), ',', '')) AS cleaned_comment
    FROM 
        part p
)
SELECT 
    ts.region_name,
    ts.nation_name,
    ts.s_name,
    pp.p_name,
    pp.p_type,
    COUNT(*) AS total_parts_processed
FROM 
    top_suppliers ts
JOIN 
    partsupp ps ON ts.s_name = (SELECT s.s_name FROM supplier s WHERE s.s_suppkey = ps.ps_suppkey)
JOIN 
    processed_parts pp ON pp.p_partkey = ps.ps_partkey
GROUP BY 
    ts.region_name, ts.nation_name, ts.s_name, pp.p_name, pp.p_type
ORDER BY 
    ts.region_name ASC, ts.nation_name ASC, ts.s_name ASC;
