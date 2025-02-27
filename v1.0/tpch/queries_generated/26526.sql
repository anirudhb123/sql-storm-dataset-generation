WITH SupplierDetails AS (
    SELECT 
        s.s_name AS supplier_name,
        s.s_address AS supplier_address,
        r.r_name AS supplier_region,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        s.s_name, s.s_address, r.r_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        COUNT(l.l_orderkey) AS total_line_items,
        SUM(l.l_extendedprice) AS total_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    sd.supplier_name,
    sd.supplier_address,
    sd.supplier_region,
    sd.part_count,
    sd.total_supply_cost,
    sd.part_names,
    os.total_line_items,
    os.total_price
FROM 
    SupplierDetails sd
JOIN 
    OrderSummary os ON sd.part_count > 0
ORDER BY 
    sd.total_supply_cost DESC, os.total_price DESC;
