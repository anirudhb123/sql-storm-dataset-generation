WITH PartReserve AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        REPLACE(SUBSTRING(p.p_comment, 1, 20), ' ', '-') AS truncated_comment,
        COALESCE(ps.ps_availqty, 0) AS available_quantity,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS return_quantity
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        p.p_retailprice > 100.00
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_comment, ps.ps_availqty
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUBSTRING(s.s_comment, 1, 30) AS short_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
)
SELECT 
    pr.p_name,
    pr.available_quantity,
    pr.truncated_comment,
    sd.s_name,
    sd.nation_name,
    sd.short_comment,
    CONCAT('Total Returns: ', CAST(pr.return_quantity AS VARCHAR)) AS return_info
FROM 
    PartReserve pr
JOIN 
    SupplierDetails sd ON pr.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sd.s_suppkey)
ORDER BY 
    pr.available_quantity DESC, 
    pr.return_quantity DESC;
