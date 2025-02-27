WITH supplier_info AS (
    SELECT 
        s.s_name AS supplier_name,
        n.n_name AS nation_name,
        s.s_acctbal AS account_balance,
        LEFT(s.s_comment, 30) AS short_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
part_info AS (
    SELECT 
        p.p_name AS part_name,
        p.p_brand AS brand,
        p.p_retailprice AS retail_price,
        CONCAT(LEFT(p.p_comment, 20), '...') AS short_comment
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 25
),
aggregated_data AS (
    SELECT 
        s.supplier_name,
        p.part_name,
        p.brand,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        supplier_info s
    JOIN 
        partsupp ps ON ps.ps_suppkey = (SELECT s_suppkey FROM supplier WHERE s_name = s.supplier_name)
    JOIN 
        part_info p ON p.part_name = (SELECT p_name FROM part WHERE p_partkey = ps.ps_partkey)
    JOIN 
        lineitem l ON l.l_partkey = ps.ps_partkey
    GROUP BY 
        s.supplier_name, p.part_name, p.brand
)
SELECT 
    ad.supplier_name,
    ad.part_name,
    ad.brand,
    ad.total_quantity,
    CASE 
        WHEN ad.total_quantity > 100 THEN 'High'
        WHEN ad.total_quantity BETWEEN 50 AND 100 THEN 'Medium'
        ELSE 'Low'
    END AS quantity_category
FROM 
    aggregated_data ad
ORDER BY 
    ad.supplier_name, ad.total_quantity DESC;
