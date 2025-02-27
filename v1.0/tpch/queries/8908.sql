WITH TotalRevenue AS (
    SELECT 
        n.n_name AS nation,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        n.n_name
),
NationRank AS (
    SELECT 
        nation,
        revenue,
        RANK() OVER (ORDER BY revenue DESC) AS rank
    FROM 
        TotalRevenue
)
SELECT 
    r.nation, 
    r.revenue, 
    r.rank,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count
FROM 
    NationRank r
JOIN 
    supplier s ON r.nation = (SELECT n_name FROM nation WHERE n_nationkey = s.s_nationkey)
WHERE 
    r.rank <= 5
GROUP BY 
    r.nation, r.revenue, r.rank
ORDER BY 
    r.rank;
