WITH RECURSIVE monthly_sales AS (
    SELECT 
        DATE_TRUNC('month', l_shipdate) AS month,
        SUM(l_extendedprice * (1 - l_discount)) AS total_sales
    FROM 
        lineitem
    WHERE 
        l_shipdate >= DATE '2021-01-01' AND l_shipdate < DATE '2022-01-01'
    GROUP BY 
        month
    UNION ALL
    SELECT 
        month + INTERVAL '1 month',
        SUM(l_extendedprice * (1 - l_discount)) AS total_sales
    FROM 
        lineitem
    WHERE 
        l_shipdate >= DATE '2021-01-01' AND l_shipdate < DATE '2022-01-01'
        AND month + INTERVAL '1 month' >= DATE '2021-01-01'
    GROUP BY 
        month + INTERVAL '1 month'
), top_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c 
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
    ORDER BY 
        total_spent DESC
    LIMIT 5
), sales_ranked AS (
    SELECT 
        month,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        monthly_sales
), supplier_performance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_value,
        COUNT(l.l_orderkey) AS order_count
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        COUNT(l.l_orderkey) > 0
), final_report AS (
    SELECT 
        r.r_name,
        t.c_name,
        COALESCE(s.total_sales, 0) AS monthly_sales,
        COALESCE(sp.supplier_value, 0) AS supplier_value,
        COALESCE(sp.order_count, 0) AS purchase_orders
    FROM 
        region r
    FULL OUTER JOIN 
        top_customers t ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = t.c_custkey LIMIT 1))
    LEFT JOIN 
        sales_ranked s ON s.month = DATE_TRUNC('month', CURRENT_DATE)
    LEFT JOIN 
        supplier_performance sp ON sp.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps LIMIT 1)
)
SELECT 
    f.r_name,
    f.c_name,
    f.monthly_sales,
    f.supplier_value,
    f.purchase_orders
FROM 
    final_report f
WHERE 
    f.monthly_sales > 1000
ORDER BY 
    f.monthly_sales DESC, f.supplier_value DESC;
