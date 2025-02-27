WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        r.r_name AS region,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, r.r_name
), OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        COUNT(l.l_orderkey) AS total_lineitems,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
)
SELECT 
    si.s_name,
    si.nation,
    si.region,
    si.total_cost,
    os.o_orderkey,
    os.o_orderstatus,
    os.total_lineitems,
    os.total_revenue
FROM 
    SupplierInfo si
JOIN 
    OrderStats os ON si.total_cost > 10000 AND os.total_revenue > 5000
ORDER BY 
    si.total_cost DESC, os.total_revenue DESC
LIMIT 50;
