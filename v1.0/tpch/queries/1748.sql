WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
HighValueCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.c_acctbal
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    r.r_name,
    COALESCE(SUM(od.total_revenue), 0) AS total_revenue,
    COUNT(DISTINCT c.c_custkey) AS high_value_customer_count,
    STRING_AGG(DISTINCT s.s_name, ', ') AS top_suppliers
FROM 
    region r
LEFT JOIN 
    nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    supplier s ON s.s_nationkey = n.n_nationkey AND s.s_suppkey IN (SELECT s_suppkey FROM RankedSuppliers WHERE rank <= 5)
LEFT JOIN 
    partsupp ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    lineitem l ON l.l_suppkey = ps.ps_suppkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    HighValueCustomers c ON c.c_custkey = o.o_custkey
LEFT JOIN 
    OrderDetails od ON od.o_orderkey = o.o_orderkey
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC;