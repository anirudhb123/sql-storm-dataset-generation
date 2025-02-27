WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_partkey) AS line_item_count,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus, o.o_orderdate
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        r.r_regionkey,
        r.r_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    ss.s_name AS supplier_name,
    ss.total_available,
    ss.part_count,
    ss.avg_supply_cost,
    os.o_orderkey,
    os.total_price,
    os.line_item_count,
    nr.r_name AS region_name
FROM 
    SupplierStats ss
LEFT JOIN 
    OrderSummary os ON ss.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = os.o_orderkey) LIMIT 1)
LEFT JOIN 
    nation n ON ss.s_suppkey = n.n_nationkey
JOIN 
    NationRegion nr ON n.n_nationkey = nr.n_nationkey
WHERE 
    ss.total_available > 100 AND 
    os.total_price IS NOT NULL
ORDER BY 
    ss.avg_supply_cost DESC, os.o_orderdate DESC;
