WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_quantity) AS total_quantity,
        COUNT(DISTINCT o.o_custkey) AS distinct_customers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice
),
NationSales AS (
    SELECT 
        n.n_name,
        SUM(o.o_totalprice) AS total_sales
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_name
)
SELECT 
    n.n_name,
    ns.total_sales,
    COALESCE(rs.total_cost, 0) AS total_supplier_cost,
    rs.s_name,
    rs.rank
FROM 
    NationSales ns
LEFT JOIN 
    RankedSuppliers rs ON ns.n_name = (SELECT n2.n_name FROM nation n2 WHERE n2.n_nationkey = rs.s_nationkey)
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    ns.total_sales > (SELECT AVG(total_sales) FROM NationSales)
ORDER BY 
    ns.total_sales DESC, rs.rank ASC;
