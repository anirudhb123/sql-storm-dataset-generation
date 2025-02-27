WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
), 
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY 
        o.o_orderkey, o.o_custkey
), 
CustomerStats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
), 
FilteredParts as (
    SELECT 
        p.p_partkey, 
        p.p_retailprice, 
        p.p_comment,
        COALESCE(NULLIF(INSTR(p.p_comment, 'fragile'), 0), 0) AS fragile_indicator
    FROM 
        part p
    WHERE 
        (p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) OR p.p_size = 10)
        AND p.p_size IS NOT NULL
)

SELECT 
    ps.ps_partkey, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(CASE ELSE l.l_extendedprice END) AS total_line_revenue, 
    AVG(fs.p_retailprice * (1 + COALESCE(NULLIF(ps.ps_supplycost / NULLIF(NULLIF(pays.p_totalprice, 0), NULL), 1),0), 0)) ) AS avg_adjusted_price,
    COUNT(DISTINCT cs.c_custkey) FILTER (WHERE cs.order_count > 3) AS high_value_customers
FROM 
    partsupp ps
LEFT JOIN 
    RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
INNER JOIN 
    RecentOrders ro ON l.l_orderkey = ro.o_orderkey
INNER JOIN 
    CustomerStats cs ON cs.c_custkey = ro.o_custkey
LEFT JOIN 
    FilteredParts fs ON fs.p_partkey = ps.ps_partkey
WHERE 
    rs.supplier_rank = 1
GROUP BY 
    ps.ps_partkey
HAVING 
    COUNT(DISTINCT rs.s_suppkey) > 2 
    OR AVG(fs.fragile_indicator) > 0
ORDER BY 
    total_line_revenue DESC
LIMIT 
    100;
