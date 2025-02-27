WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(DISTINCT ps.ps_partkey) AS part_count, 
        SUM(ps.ps_supplycost) AS total_supply_cost, 
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT ps.ps_partkey) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name AS region_name,
        r.r_comment AS region_comment,
        ns.n_nationkey,
        ns.n_name AS nation_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        RankedSuppliers rs
    JOIN 
        supplier s ON rs.s_suppkey = s.s_suppkey
    JOIN 
        nation ns ON s.s_nationkey = ns.n_nationkey
    JOIN 
        region r ON ns.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 5
    GROUP BY 
        s.s_suppkey, s.s_name, r.r_name, r.r_comment, ns.n_nationkey, ns.n_name
),
StringProcessedResults AS (
    SELECT 
        ts.s_suppkey,
        ts.s_name,
        ts.region_name,
        ts.region_comment,
        ts.nation_name,
        CONCAT('Supplier ', ts.s_name, ' from ', ts.region_name, ' - ', ts.region_comment) AS processed_string,
        ts.total_orders,
        LENGTH(CONCAT('Supplier ', ts.s_name, ' from ', ts.region_name, ' - ', ts.region_comment)) AS string_length
    FROM 
        TopSuppliers ts
)
SELECT 
    s.supp_key, 
    s.s_name, 
    s.processed_string, 
    s.total_orders, 
    s.string_length
FROM 
    StringProcessedResults s
ORDER BY 
    s.string_length DESC, 
    s.total_orders DESC;
