WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
PartStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.total_supply_value,
        rs.s_name AS top_supplier_name
    FROM 
        PartStats ps
    JOIN 
        RankedSuppliers rs ON rs.s_suppkey = (
            SELECT 
                ps.s_suppkey
            FROM 
                partsupp ps
            WHERE 
                ps.ps_partkey = p.p_partkey
            ORDER BY 
                ps.ps_supplycost DESC
            LIMIT 1
        )
    WHERE 
        ps.supplier_count > 5 AND ps.total_supply_value > 1000
)
SELECT 
    fp.p_partkey,
    fp.p_name,
    fp.total_supply_value,
    fp.top_supplier_name,
    LENGTH(fp.p_name) AS name_length,
    LEFT(fp.top_supplier_name, 5) AS short_supplier_name
FROM 
    FilteredParts fp
ORDER BY 
    fp.total_supply_value DESC;
