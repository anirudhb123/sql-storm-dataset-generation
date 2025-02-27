WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
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
    GROUP BY 
        r.r_name
),
CustomerOrders AS (
    SELECT 
        c.c_name AS customer_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_spent
    FROM 
        customer c 
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name
),
OrderAnalysis AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS status_rank
    FROM 
        orders o
),
HighValueCustomers AS (
    SELECT 
        c.c_name,
        c.c_custkey,
        (CASE 
            WHEN c.c_acctbal IS NULL THEN 0 
            ELSE c.c_acctbal END * 1.1) AS adjusted_balance
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_acctbal IS NOT NULL)
        AND c.c_comment NOT LIKE '%defective%'
)
SELECT 
    r.region_name,
    c.customer_name,
    co.order_count,
    COALESCE(s.total_sales,0) AS total_sales,
    h.adjusted_balance,
    (SELECT COUNT(*) FROM OrderAnalysis WHERE status_rank = 1) AS top_orders_count,
    MAX(o.o_totalprice) AS maximum_order_value
FROM 
    RegionalSales s
FULL OUTER JOIN 
    HighValueCustomers h ON h.adjusted_balance > 10000
JOIN 
    CustomerOrders co ON co.customer_name = h.c_name
RIGHT JOIN 
    (SELECT DISTINCT r_name FROM region) r ON s.region_name = r.r_name
LEFT JOIN 
    OrderAnalysis o ON o.o_orderkey = co.order_count
GROUP BY 
    r.region_name, c.customer_name, h.adjusted_balance
HAVING 
    SUM(co.total_spent) > 5000
ORDER BY 
    r.region_name, adjusted_balance DESC;
