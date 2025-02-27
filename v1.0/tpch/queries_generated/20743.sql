WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
        o.o_orderstatus,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus, o.o_orderdate
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END), 0) AS total_returned,
    COALESCE(SUM(CASE WHEN l.l_returnflag <> 'R' THEN l.l_quantity ELSE 0 END), 0) AS total_sold,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    ROUND(AVG(CASE WHEN o.o_orderstatus = 'O' THEN od.total_revenue END), 2) AS average_open_order_revenue,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_suppkey, ')')) AS supplier_list
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    OrderDetails od ON l.l_orderkey = od.o_orderkey
LEFT JOIN 
    RankedSuppliers s ON s.s_suppkey = l.l_suppkey AND s.rank = 1
LEFT JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    total_sold - total_returned > 10
ORDER BY 
    p.p_partkey;
