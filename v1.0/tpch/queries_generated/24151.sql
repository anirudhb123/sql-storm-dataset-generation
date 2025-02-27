WITH RECURSIVE bell_curve AS (
    SELECT 
        n_nationkey,
        n_name,
        ROW_NUMBER() OVER (ORDER BY random()) AS position
    FROM 
        nation
    WHERE 
        n_nationkey IS NOT NULL
), 
filtered_customers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal,
        (SELECT SUM(o.o_totalprice) FROM orders o WHERE o.o_custkey = c.c_custkey) AS total_spent
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
    ORDER BY 
        total_spent DESC
    LIMIT 100
),
supplier_part_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ROUND(p.p_retailprice * (1 - NULLIF(MAX(l.l_discount) OVER(PARTITION BY l.l_partkey), 0)), 2) AS adjusted_price
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        s.s_acctbal < 500
)
SELECT 
    f.c_name,
    COUNT(DISTINCT s.s_suppkey) AS number_of_suppliers, 
    SUM(sai.adjusted_price) AS total_adjusted_price,
    AVG(CASE WHEN sai.adjusted_price IS NOT NULL THEN sai.adjusted_price ELSE 0 END) AS avg_price,
    MAX(CASE WHEN sai.adj_price < 100 THEN 1 ELSE 0 END) AS flag_low_price,
    SUM(CASE WHEN b.position IS NULL THEN 1 ELSE 0 END) AS null_bell_curve_entries
FROM 
    filtered_customers f
LEFT JOIN 
    supplier_part_info sai ON f.c_custkey = (
        SELECT p.ps_suppkey
        FROM partsupp p
        WHERE p.ps_partkey IN (
            SELECT ps.ps_partkey
            FROM partsupp ps
            WHERE ps.ps_suppkey = f.c_custkey)
    )
FULL OUTER JOIN 
    bell_curve b ON b.position = (
        SELECT AVG(position) FROM bell_curve
        WHERE n_nationkey = b.n_nationkey)
GROUP BY 
    f.c_name
ORDER BY 
    total_adjusted_price DESC;
