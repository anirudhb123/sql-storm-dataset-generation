WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS ranking
    FROM 
        supplier s
), 
TopSuppliers AS (
    SELECT * 
    FROM RankedSuppliers 
    WHERE ranking <= 3
), 
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        c.c_mktsegment,
        (SELECT AVG(o.o_totalprice) 
         FROM orders o 
         WHERE o.o_custkey = c.c_custkey) AS avg_order_value
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
), 
OrderLineDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)

SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(ol.total_lineitem_value) AS total_order_value,
    AVG(h.avg_order_value) AS average_order_value,
    COALESCE(MAX(ts.s_acctbal), 0) AS max_supplier_acctbal,
    CASE 
        WHEN COUNT(DISTINCT c.c_custkey) > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS customer_status
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    TopSuppliers ts ON n.n_nationkey = (SELECT s_nationkey FROM supplier WHERE s_suppkey = ts.s_suppkey LIMIT 1)
LEFT JOIN 
    HighValueCustomers h ON c.c_custkey = h.c_custkey
JOIN 
    OrderLineDetails ol ON ol.o_orderkey IN (SELECT o_orderkey FROM orders WHERE o_custkey = c.c_custkey)
WHERE 
    r.r_name IS NOT NULL 
    AND (c.c_mktsegment IS NOT NULL OR h.c_custkey IS NOT NULL)
GROUP BY 
    r.r_name
HAVING 
    SUM(ol.total_lineitem_value) > 1000000
ORDER BY 
    r.r_name DESC
WITH ROLLUP;
