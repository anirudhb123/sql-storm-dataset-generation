WITH CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopRegions AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(o.o_totalprice) DESC) AS region_rank
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        n.n_regionkey, r.r_name
    HAVING 
        SUM(o.o_totalprice) IS NOT NULL
),
MaxRevenue AS (
    SELECT 
        MAX(total_spent) AS max_spent
    FROM 
        CustomerOrderSummary
)
SELECT 
    c.c_name,
    cos.order_count,
    cos.total_spent,
    tr.r_name AS top_region,
    CASE 
        WHEN cos.total_spent > (SELECT max_spent FROM MaxRevenue) THEN 'High Roller'
        ELSE 'Regular'
    END AS customer_type,
    STRING_AGG(DISTINCT l.l_shipmode || ' ' || l.l_returnflag, '; ') AS shipping_modes
FROM 
    CustomerOrderSummary cos
LEFT JOIN 
    TopRegions tr ON cos.c_custkey = (SELECT TOP 1 c2.c_custkey FROM CustomerOrderSummary c2 WHERE c2.order_count = cos.order_count ORDER BY c2.total_spent DESC)
JOIN 
    lineitem l ON l.l_orderkey IN (SELECT o_orderkey FROM orders WHERE o_custkey = cos.c_custkey)
GROUP BY 
    c.c_name, cos.order_count, cos.total_spent, tr.r_name
HAVING 
    COUNT(l.l_orderkey) > 0
ORDER BY 
    cos.total_spent DESC;
