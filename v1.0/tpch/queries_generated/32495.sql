WITH RECURSIVE CTE_NationSales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        n.n_nationkey, n.n_name
), CTE_CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), CTE_SupplierPart AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS supplied_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    n.n_name AS nation_name,
    c.c_name AS customer_name,
    s.s_name AS supplier_name,
    Coalesce(cte_ns.total_sales, 0) AS nation_total_sales,
    COALESCE(cte_co.total_order_value, 0) AS customer_total_orders,
    COALESCE(cte_sp.supplied_parts, 0) AS supplier_part_count,
    CASE 
        WHEN COALESCE(cte_ns.total_sales, 0) > 10000 THEN 'High Sales'
        WHEN COALESCE(cte_ns.total_sales, 0) > 5000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    nation n
LEFT JOIN 
    CTE_NationSales cte_ns ON n.n_nationkey = cte_ns.n_nationkey
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    CTE_CustomerOrders cte_co ON c.c_custkey = cte_co.c_custkey
LEFT JOIN 
    supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    CTE_SupplierPart cte_sp ON s.s_suppkey = cte_sp.s_suppkey
WHERE 
    (cte_co.order_count > 0 OR cte_ns.total_sales IS NOT NULL)
ORDER BY 
    nation_name, customer_name, supplier_name;
