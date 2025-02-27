
WITH SupplierDetails AS (
    SELECT 
        s.s_name, 
        s.s_address, 
        n.n_name AS nation_name, 
        r.r_name AS region_name,
        s.s_acctbal, 
        s.s_comment,
        REPLACE(LOWER(s.s_comment), ' ', '_') AS modified_comment,
        LENGTH(s.s_comment) AS comment_length,
        s.s_suppkey
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
        SUBSTRING(p.p_name, 1, 10) AS short_name, 
        LENGTH(p.p_name) AS name_length
    FROM 
        part p
),
AggregatedData AS (
    SELECT 
        sd.s_name,
        sd.nation_name,
        sd.region_name,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts,
        SUM(ld.l_discount) AS total_discount,
        AVG(ld.l_extendedprice) AS avg_extended_price,
        STRING_AGG(DISTINCT pd.short_name, ', ') AS example_part_names
    FROM 
        SupplierDetails sd
    JOIN 
        partsupp ps ON sd.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem ld ON ps.ps_partkey = ld.l_partkey
    JOIN 
        PartDetails pd ON ld.l_partkey = pd.p_partkey
    WHERE 
        LENGTH(sd.s_comment) > 50
    GROUP BY 
        sd.s_name, sd.nation_name, sd.region_name
)
SELECT 
    a.s_name,
    a.nation_name,
    a.region_name,
    a.supplied_parts,
    a.total_discount,
    a.avg_extended_price,
    a.example_part_names
FROM 
    AggregatedData a
WHERE 
    a.total_discount > 1000
ORDER BY 
    a.avg_extended_price DESC, a.supplied_parts ASC;
