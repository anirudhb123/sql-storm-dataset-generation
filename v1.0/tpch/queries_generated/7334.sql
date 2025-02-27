WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, 
        s.s_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        o.o_orderdate,
        o.o_orderstatus
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_orderstatus
),
Regions AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name, 
        r.r_name
)
SELECT 
    ss.s_name,
    ss.total_supply_cost,
    os.total_order_value,
    r.region_name,
    r.nation_name,
    r.supplier_count
FROM 
    SupplierStats ss
JOIN 
    OrderStats os ON ss.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps ORDER BY ps.ps_supplycost DESC LIMIT 1)
JOIN 
    Regions r ON ss.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 20))
WHERE 
    os.total_order_value > (SELECT AVG(total_order_value) FROM OrderStats);
