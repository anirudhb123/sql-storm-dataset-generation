WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) as rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N' 
        AND o.o_orderdate >= DATE '2023-01-01' 
        AND o.o_orderdate <= DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderpriority
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000.00
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        SUM(ps.ps_availqty) as total_avail_qty
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey, p.p_name
    HAVING 
        SUM(ps.ps_availqty) > 500
)
SELECT 
    r.r_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(o.o_totalprice) AS total_revenue,
    AVG(o.o_totalprice) AS avg_order_value,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
LEFT JOIN 
    orders o ON rs.s_suppkey = o.o_custkey
LEFT JOIN 
    SupplierParts sp ON sp.ps_suppkey = s.s_suppkey
WHERE 
    rs.rank <= 3 
    AND o.o_orderstatus = 'F'
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC 
LIMIT 10
UNION
SELECT 
    'Summary' AS r_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(o.o_totalprice) AS total_revenue,
    AVG(o.o_totalprice) AS avg_order_value,
    NULL AS part_names
FROM 
    orders o
WHERE 
    o.o_orderdate < DATE '2023-01-01';
