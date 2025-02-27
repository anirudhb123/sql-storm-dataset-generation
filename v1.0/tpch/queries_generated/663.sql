WITH NationalSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
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
        n.n_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopNations AS (
    SELECT 
        nation_name, 
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        NationalSales
),
OrderDetails AS (
    SELECT 
        o.orderkey,
        o.orderdate,
        os.order_total,
        COALESCE(n.country, 'Unknown') AS nation,
        CASE 
            WHEN os.order_total > 10000 THEN 'High Value'
            WHEN os.order_total > 5000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS order_value_category
    FROM 
        OrderStats os
    LEFT JOIN 
        customer c ON os.o_orderkey = c.c_custkey
    LEFT JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
)
SELECT 
    dt.nation,
    COUNT(dt.orderkey) AS num_orders,
    AVG(dt.order_total) AS avg_order_total,
    SUM(dt.order_total) AS total_order_value
FROM 
    OrderDetails dt
WHERE 
    dt.nation IS NOT NULL
GROUP BY 
    dt.nation
HAVING 
    COUNT(dt.orderkey) > 5
ORDER BY 
    total_order_value DESC
LIMIT 10;
