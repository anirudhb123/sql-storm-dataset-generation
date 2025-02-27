WITH OrderedSales AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_custkey
),
CustomerSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(os.total_sales), 0) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        OrderedSales os ON o.o_orderkey = os.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cs.c_custkey,
    cs.c_name,
    cs.total_sales,
    cs.order_count,
    CASE 
        WHEN cs.total_sales >= 10000 THEN 'Platinum'
        WHEN cs.total_sales >= 5000 THEN 'Gold'
        ELSE 'Silver'
    END AS customer_tier
FROM 
    CustomerSales cs
WHERE 
    cs.order_count > (
        SELECT AVG(order_count) 
        FROM (
            SELECT COUNT(DISTINCT o.o_orderkey) AS order_count
            FROM orders o
            GROUP BY o.o_custkey
        ) AS temp
    )
ORDER BY 
    cs.total_sales DESC
LIMIT 10;

-- Additional Query Section for Benchmarking
SELECT 
    p.p_name,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey AND s.s_acctbal IS NOT NULL
GROUP BY 
    p.p_name
HAVING 
    total_supply_cost > 10000 OR total_supply_cost IS NULL
ORDER BY 
    total_supply_cost DESC;
