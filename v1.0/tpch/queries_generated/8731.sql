WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT c.c_custkey) AS unique_customers,
        COUNT(l.l_linenumber) AS lineitem_count
    FROM 
        orders o 
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND 
        o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierStats AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts
    FROM 
        partsupp ps 
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_suppkey
),
NationRevenue AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(os.total_revenue) AS nation_revenue
    FROM 
        OrderSummary os 
    JOIN 
        customer c ON os.unique_customers = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.r_regionkey,
    r.r_name,
    nr.nation_revenue,
    ss.total_cost,
    ss.supplied_parts
FROM 
    region r 
LEFT JOIN 
    NationRevenue nr ON r.r_regionkey = nr.n_nationkey
LEFT JOIN 
    SupplierStats ss ON ss.ps_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps JOIN supplier s ON ps.ps_suppkey = s.s_suppkey WHERE s.s_nationkey = nr.n_nationkey)
ORDER BY 
    r.r_regionkey, nr.nation_revenue DESC, ss.total_cost DESC;
