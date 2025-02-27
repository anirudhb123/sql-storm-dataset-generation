WITH SupplierOrders AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        COUNT(DISTINCT CASE WHEN o.o_orderstatus = 'F' THEN o.o_orderkey END) > 5
    ORDER BY 
        revenue_rank
    LIMIT 10
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COALESCE(CAST(ROUND(AVG(o.o_totalprice), 2) AS DECIMAL(12, 2)), 0) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
)
SELECT 
    c.c_name,
    c.c_acctbal,
    COALESCE(t.total_revenue, 0) AS top_supplier_revenue,
    cd.avg_order_value
FROM 
    CustomerDetails cd
LEFT JOIN 
    TopSuppliers t ON cd.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_name = (SELECT s.s_name FROM supplier s WHERE s.s_suppkey = t.s_suppkey LIMIT 1))
WHERE 
    cd.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'A%'))
ORDER BY 
    cd.c_acctbal DESC;
