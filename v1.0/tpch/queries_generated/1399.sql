WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
), 
OrderCustomer AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice, c.c_name, c.c_nationkey
)

SELECT 
    p.p_name,
    p.p_brand,
    COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END), 0) AS returned_quantity,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS net_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    NS.total_nation_sales
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    OrderCustomer o ON o.o_totalprice > 1000 OR o.c_nationkey IS NULL
LEFT JOIN 
    (SELECT 
        n.n_nationkey, 
        SUM(o.o_totalprice) AS total_nation_sales
     FROM 
        nation n
     JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
     JOIN 
        orders o ON c.c_custkey = o.o_custkey
     GROUP BY 
        n.n_nationkey) NS ON l.l_suppkey IN (SELECT s.s_suppkey FROM RankedSuppliers s WHERE s.rnk = 1)
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, NS.total_nation_sales
HAVING 
    net_revenue > 10000 OR returned_quantity > 5
ORDER BY 
    net_revenue DESC;
