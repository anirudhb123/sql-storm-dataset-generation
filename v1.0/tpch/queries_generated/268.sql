WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_revenue,
        ss.order_count,
        RANK() OVER (ORDER BY ss.total_revenue DESC) AS revenue_rank
    FROM 
        supplier s
    LEFT JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
),
FilteredSuppliers AS (
    SELECT 
        r.s_suppkey,
        r.s_name,
        r.total_revenue,
        r.order_count
    FROM 
        RankedSuppliers r
    WHERE 
        r.revenue_rank <= 10 OR r.total_revenue IS NULL
)

SELECT 
    p.p_partkey,
    p.p_name,
    fs.s_suppkey,
    fs.s_name,
    COALESCE(fs.total_revenue, 0) AS total_revenue,
    COALESCE(fs.order_count, 0) AS order_count,
    p.p_retailprice,
    p.p_comment
FROM 
    part p
LEFT JOIN 
    FilteredSuppliers fs ON p.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = fs.s_suppkey LIMIT 1) -- Using correlated subquery
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size > 10) -- Using average price for filtering
ORDER BY 
    total_revenue DESC, p.p_retailprice ASC;
