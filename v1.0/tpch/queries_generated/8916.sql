WITH TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    ORDER BY 
        total_supply_cost DESC
    LIMIT 10
),
OrdersSummary AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
RegionNation AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        r.r_regionkey, 
        r.r_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    rn.r_name AS region_name,
    rn.n_name AS nation_name,
    ts.s_name AS supplier_name,
    os.total_revenue,
    os.o_orderdate
FROM 
    OrdersSummary os
JOIN 
    TopSuppliers ts ON ts.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps JOIN lineitem l ON ps.ps_partkey = l.l_partkey WHERE l.l_orderkey = os.o_orderkey LIMIT 1)
JOIN 
    lineitem l ON os.o_orderkey = l.l_orderkey
JOIN 
    RegionNation rn ON rn.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = os.o_orderkey LIMIT 1)
WHERE 
    os.total_revenue > 10000
ORDER BY 
    region_name, total_revenue DESC;
