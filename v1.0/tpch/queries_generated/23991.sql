WITH RegionalSales AS (
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
        o.o_orderdate >= '1995-01-01' AND o.o_orderdate < (CURRENT_DATE - INTERVAL '1' DAY)
    GROUP BY 
        n.n_name
),
TopNations AS (
    SELECT 
        nation_name
    FROM 
        RegionalSales
    WHERE 
        sales_rank <= 3
)
SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    COALESCE(MAX(ps.ps_supplycost), 0) AS max_supply_cost,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE NULL END) AS returned_quantity,
    SUM(CASE 
            WHEN l.l_tax IS NULL or l.l_tax = 0 THEN l.l_extendedprice * 0.1
            ELSE l.l_extendedprice * l.l_tax 
        END) AS additional_tax_revenue
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    TopNations tn ON n.n_name = tn.nation_name
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
GROUP BY 
    p.p_name
HAVING 
    SUM(ps.ps_availqty) > 0
ORDER BY 
    supplier_count DESC, max_supply_cost ASC;
