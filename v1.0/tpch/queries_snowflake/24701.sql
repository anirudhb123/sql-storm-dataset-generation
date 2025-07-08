WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        DENSE_RANK() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
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
        r.r_regionkey, r.r_name
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        COALESCE(SUM(o.o_totalprice), 0) AS total_spent,
        COUNT(o.o_orderkey) AS orders_placed,
        MAX(CASE WHEN o.o_orderstatus = 'F' THEN o.o_orderdate ELSE NULL END) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.region_name,
    cs.c_custkey,
    cs.total_spent,
    cs.orders_placed,
    r.total_sales,
    CASE 
        WHEN cs.last_order_date IS NULL THEN 'No orders placed'
        WHEN cs.total_spent > r.total_sales THEN 'High spender'
        ELSE 'Regular customer' 
    END AS customer_status,
    CASE 
        WHEN cs.orders_placed IS NULL OR cs.orders_placed = 0 THEN 'Never'
        WHEN cs.orders_placed = 1 THEN 'Once'
        ELSE 'Multiple' 
    END AS frequency
FROM 
    RegionalSales r
JOIN 
    CustomerStats cs ON r.region_name = (SELECT r_name FROM region WHERE r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = cs.c_custkey))
FULL OUTER JOIN 
    (SELECT 
        DISTINCT p.p_name 
     FROM 
        part p 
     WHERE 
        p.p_size IS NOT NULL 
        AND LENGTH(p.p_name) > 5
        AND p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    ) obscure_parts ON obscure_parts.p_name IS NOT NULL  
WHERE 
    r.total_sales IS NOT NULL 
    AND (cs.total_spent BETWEEN 1000 AND 10000 OR cs.total_spent IS NULL) 
ORDER BY 
    r.total_sales DESC, 
    cs.orders_placed ASC;
