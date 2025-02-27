WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 0
), 
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value,
        COUNT(*) AS line_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY
        o.o_orderkey, o.o_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
), 
CustomerInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name,
        RANK() OVER (ORDER BY c.c_acctbal DESC) AS cust_rank
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
)

SELECT 
    ci.cust_rank,
    ci.c_name,
    ci.nation_name,
    o.o_orderkey,
    o.order_value,
    COALESCE(rs.s_name, 'No Supplier') AS top_supplier,
    rs.s_acctbal,
    CASE 
        WHEN ci.cust_rank <= 5 THEN 'Top Customer'
        WHEN ci.cust_rank <= 10 THEN 'Mid Customer'
        ELSE 'Low Customer'
    END AS customer_segment
FROM 
    HighValueOrders o
JOIN 
    CustomerInfo ci ON o.o_custkey = ci.c_custkey
LEFT JOIN 
    RankedSuppliers rs ON ci.nation_name = (SELECT n.n_name 
                                              FROM nation n 
                                              WHERE n.n_nationkey = (SELECT c.c_nationkey 
                                                                      FROM customer c 
                                                                      WHERE c.c_custkey = o.o_custkey))
WHERE 
    o.line_count > 2 
    AND (o.order_value > (SELECT AVG(order_value) FROM HighValueOrders) OR o.o_orderkey IS NULL)
ORDER BY 
    ci.cust_rank, o.order_value DESC;
