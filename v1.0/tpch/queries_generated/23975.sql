WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        r.r_name
), 
CustomerSegmentation AS (
    SELECT 
        c.c_name,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rank,
        SUM(l.l_extendedprice) AS segment_sales
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_name, c.c_mktsegment
),
HighValueCustomers AS (
    SELECT 
        c.c_name,
        c.c_acctbal,
        COALESCE(CASE WHEN c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2) THEN 'High' ELSE 'Low' END, 'Unknown') AS value_classification
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL
)
SELECT 
    r.region_name,
    SUM(r.total_sales) AS total_sales,
    AVG(cs.segment_sales) AS avg_segment_sales,
    COUNT(DISTINCT hvc.c_name) FILTER (WHERE hvc.value_classification = 'High') AS high_value_customers
FROM 
    RegionalSales r
JOIN 
    CustomerSegmentation cs ON cs.segment_sales > 0
LEFT JOIN 
    HighValueCustomers hvc ON cs.c_name = hvc.c_name
WHERE 
    r.total_orders > (
        SELECT 
            AVG(total_orders) FROM RegionalSales
    )
GROUP BY 
    r.region_name
HAVING 
    SUM(r.total_sales) > 10000
ORDER BY 
    r.region_name ASC;
