WITH RECURSIVE sales_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
    GROUP BY 
        c.c_custkey, c.c_name
), ranked_sales AS (
    SELECT 
        *,
        CASE 
            WHEN total_sales IS NULL THEN 'No Sales'
            ELSE 'Sales'
        END AS sales_status
    FROM 
        sales_summary
    WHERE 
        rn <= 10
)
SELECT 
    c.c_custkey,
    c.c_name,
    COALESCE(s.total_sales, 0) AS total_sales,
    c.c_acctbal,
    CASE 
        WHEN r.sales_status = 'No Sales' THEN 'Inactive'
        ELSE 'Active'
    END AS customer_status,
    COALESCE((
        SELECT 
            SUM(p.ps_supplycost * p.ps_availqty)
        FROM 
            partsupp p
        JOIN 
            part p2 ON p.ps_partkey = p2.p_partkey
        WHERE 
            p.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = c.c_nationkey)
    ), 0) AS total_supplier_cost
FROM 
    customer c
LEFT JOIN 
    ranked_sales s ON c.c_custkey = s.c_custkey
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
ORDER BY 
    total_sales DESC, c.c_name;
