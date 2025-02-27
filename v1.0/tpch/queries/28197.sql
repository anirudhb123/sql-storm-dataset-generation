WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        n.n_name AS nation_name, 
        r.r_name AS region_name, 
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_availqty) AS total_availqty,
        SUM(ps.ps_supplycost) AS total_supplycost,
        STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
        STRING_AGG(DISTINCT p.p_brand, ', ') AS part_brands
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, n.n_name, r.r_name
),
CombinedData AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        s.nation_name, 
        s.region_name, 
        s.part_count, 
        s.total_availqty, 
        s.total_supplycost, 
        s.part_names, 
        s.part_brands,
        ROW_NUMBER() OVER (ORDER BY s.total_availqty DESC) AS rank
    FROM 
        SupplierDetails s
)
SELECT 
    CONCAT(s.s_name, ' (', s.nation_name, ', ', s.region_name, ')') AS supplier_info,
    s.part_count,
    s.total_availqty,
    s.total_supplycost,
    s.part_names,
    s.part_brands
FROM 
    CombinedData s
WHERE 
    s.rank <= 10
ORDER BY 
    s.rank;
