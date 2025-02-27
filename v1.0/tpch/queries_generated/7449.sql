WITH OrderedItems AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        c.c_mktsegment,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
        AND l.l_shipdate > o.o_orderdate
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_mktsegment, n.n_name, r.r_name
), RankedSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY mktsegment ORDER BY total_revenue DESC) AS rank
    FROM 
        OrderedItems
)
SELECT 
    nation_name,
    region_name,
    mktsegment,
    total_revenue
FROM 
    RankedSales
WHERE 
    rank <= 10
ORDER BY 
    mktsegment, total_revenue DESC;
