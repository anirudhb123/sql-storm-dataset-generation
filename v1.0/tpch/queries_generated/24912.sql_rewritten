WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS spend_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        AVG(ps.ps_supplycost) < (SELECT AVG(ps_supplycost) FROM partsupp)
),
RecentOrders AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_extendedprice,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_receiptdate DESC) AS rn
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= cast('1998-10-01' as date) - INTERVAL '30 days'
)

SELECT 
    p.p_name,
    p.p_brand,
    COALESCE(SUM(lo.l_extendedprice * (1 - lo.l_discount)), 0) AS total_revenue,
    COUNT(DISTINCT CASE WHEN rc.spend_rank <= 5 THEN rc.c_custkey END) AS high_value_customer_count,
    AVG(hvs.avg_supply_cost) AS average_supply_cost,
    CASE 
        WHEN COUNT(DISTINCT rc.c_custkey) = 0 THEN 'No customers'
        ELSE 'Customers exist'
    END AS customer_status
FROM 
    part p
LEFT JOIN 
    lineitem lo ON p.p_partkey = lo.l_partkey
LEFT JOIN 
    RecentOrders ro ON lo.l_orderkey = ro.l_orderkey
LEFT JOIN 
    RankedCustomers rc ON rc.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_custkey IS NOT NULL ORDER BY RANDOM() LIMIT 1)
LEFT JOIN 
    HighValueSuppliers hvs ON lo.l_suppkey = hvs.s_suppkey 
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand
ORDER BY 
    total_revenue DESC
LIMIT 10;