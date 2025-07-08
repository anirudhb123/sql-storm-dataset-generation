
WITH NationCounts AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(s.s_suppkey) AS supplier_count,
        LISTAGG(s.s_name, ', ') AS suppliers
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
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
        LISTAGG(DISTINCT CONCAT(s.s_name, ' (', s.s_acctbal, ')'), '; ') AS supplier_details
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_size, p.p_retailprice, p.p_comment
)
SELECT 
    nc.nation_name,
    nc.supplier_count,
    pd.p_name,
    pd.p_brand,
    pd.p_type,
    pd.p_retailprice,
    pd.supplier_details
FROM 
    NationCounts nc
JOIN 
    PartDetails pd ON pd.p_partkey IN (
        SELECT ps.ps_partkey
        FROM partsupp ps
        JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
        WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = nc.nation_name)
    )
ORDER BY 
    nc.nation_name, pd.p_name;
