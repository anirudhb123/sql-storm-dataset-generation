WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
ActiveOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND l.l_discount > 0
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus
)
SELECT 
    p.p_name,
    r.r_name,
    COUNT(DISTINCT CASE WHEN rs.rank <= 3 THEN rs.s_suppkey END) AS top_suppliers_count,
    AVG(ao.total_quantity) AS average_order_quantity,
    SUM(ao.o_totalprice) AS total_revenue,
    TRIM(LEADING '0' FROM CAST(p.p_retailprice AS VARCHAR(10))) AS formatted_price
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    rankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey
JOIN 
    ActiveOrders ao ON ao.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey)
JOIN 
    nation n ON rs.s_suppkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    p.p_name, r.r_name
HAVING 
    COUNT(DISTINCT CASE WHEN rs.rank <= 3 THEN rs.s_suppkey END) > 1
ORDER BY 
    total_revenue DESC, average_order_quantity DESC
LIMIT 10;
