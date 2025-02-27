WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS orders_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        r.r_name
), HighValueCustomers AS (
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
    HAVING 
        SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders)
), DetailedLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_discount,
        l.l_extendedprice,
        DENSE_RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS item_rank
    FROM 
        lineitem l
)
SELECT 
    r.region_name,
    COALESCE(SUM(h.total_spent), 0) AS high_value_customers_total,
    COALESCE(SUM(s.total_sales), 0) AS regional_sales_total,
    COUNT(DISTINCT d.l_orderkey) AS total_orders,
    COUNT(DISTINCT d.item_rank) AS unique_items_count
FROM 
    RegionalSales s
FULL OUTER JOIN 
    HighValueCustomers h ON s.region_name = (SELECT r.r_name FROM nation n JOIN region r ON n.n_regionkey = r.r_regionkey WHERE n.n_nationkey = h.c_custkey)
LEFT JOIN 
    DetailedLineItems d ON d.l_orderkey = h.c_custkey
GROUP BY 
    r.region_name
ORDER BY 
    r.region_name;
