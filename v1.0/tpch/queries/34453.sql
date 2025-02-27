WITH RECURSIVE FrequentSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate <= DATE '1997-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        COUNT(l.l_orderkey) > 1
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT f.s_suppkey) AS supplier_count,
    SUM(co.o_totalprice) AS total_customer_spent,
    AVG(f.total_sales) AS avg_supplier_sales
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    FrequentSuppliers f ON s.s_suppkey = f.s_suppkey
LEFT JOIN 
    CustomerOrders co ON co.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey LIMIT 1)
WHERE 
    (f.sales_rank <= 5 OR f.sales_rank IS NULL)
    AND (co.order_rank = 1 OR co.order_rank IS NULL)
GROUP BY 
    r.r_name
ORDER BY 
    total_customer_spent DESC;