WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
RegionStats AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    ss.s_name,
    ss.total_available_quantity,
    ss.total_cost,
    ss.part_count,
    os.c_name,
    os.order_count,
    os.total_spent,
    rs.r_name,
    rs.nation_count
FROM 
    SupplierStats ss
JOIN 
    OrderStats os ON ss.part_count > 0
JOIN 
    RegionStats rs ON ss.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p))
WHERE 
    os.total_spent > 1000
ORDER BY 
    ss.total_available_quantity DESC, 
    os.total_spent DESC
LIMIT 50;
