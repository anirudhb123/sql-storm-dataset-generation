WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        o.o_clerk,
        o.o_shippriority,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY l.l_linenumber) AS line_num,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Completed'
            ELSE 'Pending'
        END AS order_status_description
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
),
AggregatedSales AS (
    SELECT 
        oh.o_orderkey,
        SUM(oh.l_extendedprice * (1 - oh.l_discount)) AS total_sales,
        COUNT(*) FILTER (WHERE oh.l_returnflag = 'R') AS return_count
    FROM 
        OrderHierarchy oh
    GROUP BY 
        oh.o_orderkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    c.c_name AS customer_name,
    SUM(as.total_sales) AS total_sales_per_customer,
    AVG(as.total_sales) AS avg_sales_per_customer,
    COALESCE(MAX(as.total_sales), 0) AS max_sales_per_order,
    COUNT(DISTINCT oh.o_orderkey) AS orders_count,
    CASE 
        WHEN SUM(as.total_sales) IS NULL THEN 'No Sales'
        WHEN SUM(as.total_sales) > 10000 THEN 'High Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    AggregatedSales as
JOIN 
    customer c ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = as.o_orderkey)
JOIN 
    supplier s ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT oh.l_partkey FROM OrderHierarchy oh WHERE oh.o_orderkey = as.o_orderkey))
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    r.r_name, n.n_name, c.c_name
HAVING 
    (SUM(as.total_sales) > 500 OR COUNT(DISTINCT oh.o_orderkey) > 10)
ORDER BY 
    total_sales_per_customer DESC NULLS LAST;
