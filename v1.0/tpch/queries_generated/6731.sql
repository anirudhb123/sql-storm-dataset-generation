WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS unique_customers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '2022-01-01' AND 
        l.l_shipdate < DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopRegions AS (
    SELECT 
        n.n_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_name
    ORDER BY 
        total_cost DESC
    LIMIT 5
)
SELECT 
    ts.n_name AS region_name,
    os.o_orderdate,
    os.total_revenue,
    os.unique_customers
FROM 
    OrderSummary os
JOIN 
    TopRegions ts ON os.o_orderkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = ts.n_name)))
ORDER BY 
    os.total_revenue DESC, os.o_orderdate;
