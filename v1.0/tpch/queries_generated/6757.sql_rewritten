WITH RankedSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        n.n_name
),
TopNations AS (
    SELECT 
        nation_name,
        total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    p.p_comment,
    ts.nation_name,
    ts.total_sales
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    TopNations ts ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = ts.nation_name)
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
ORDER BY 
    ts.total_sales DESC, p.p_retailprice ASC;