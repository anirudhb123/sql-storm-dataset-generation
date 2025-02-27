WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(ps.ps_partkey) AS part_count, 
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY COUNT(ps.ps_partkey) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_partkey) AS lineitem_count,
        FIRST_VALUE(l.l_shipmode) OVER (PARTITION BY o.o_orderkey ORDER BY l.l_lineitemdate DESC) AS last_shipmode
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'F') AND
        l.l_shipdate IS NOT NULL
    GROUP BY 
        o.o_orderkey
), 
TotalRevenue AS (
    SELECT 
        CASE 
            WHEN c.c_mktsegment = 'BUILDING' THEN SUM(od.total_price) 
            ELSE SUM(od.total_price * 1.05) 
        END AS revenue,
        COUNT(od.o_orderkey) AS order_count,
        c.c_name
    FROM 
        OrderDetails od
    JOIN 
        customer c ON od.o_orderkey = c.c_custkey 
    GROUP BY 
        c.c_name, c.c_mktsegment
) 
SELECT 
    r.r_name, 
    MAX(tr.revenue) AS max_revenue,
    ARRAY_AGG(DISTINCT rs.s_name) FILTER (WHERE rs.supplier_rank <= 3) AS top_suppliers
FROM 
    TotalRevenue tr
JOIN 
    nation n ON tr.c_name = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT OUTER JOIN 
    RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey
GROUP BY 
    r.r_name
HAVING 
    MAX(tr.revenue) IS NOT NULL AND 
    COUNT(tr.o_orderkey) > 10
ORDER BY 
    r.r_name DESC;
