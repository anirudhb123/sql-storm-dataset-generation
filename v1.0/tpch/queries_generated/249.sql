WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
),
SupplierStats AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS average_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
),
CustomerStatistics AS (
    SELECT
        c.c_custkey,
        c.c_name,
        CASE 
            WHEN c.c_acctbal > 500 THEN 'High'
            WHEN c.c_acctbal BETWEEN 100 AND 500 THEN 'Medium'
            ELSE 'Low'
        END AS balance_category
    FROM 
        customer c
),
RecentLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS order_count,
        LAG(SUM(l.l_extendedprice * (1 - l.l_discount))) OVER (ORDER BY l.l_shipdate DESC) AS prev_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        l.l_orderkey
)

SELECT 
    r.o_orderkey,
    r.o_orderdate,
    COALESCE(SUM(rl.total_revenue), 0) AS total_revenue,
    COALESCE(c.balance_category, 'N/A') AS customer_balance_category,
    ss.total_available,
    ss.average_cost
FROM 
    RankedOrders r
LEFT JOIN 
    RecentLineItems rl ON r.o_orderkey = rl.l_orderkey
LEFT JOIN 
    customer c ON r.o_custkey = c.c_custkey
JOIN 
    SupplierStats ss ON ss.ps_suppkey IN (SELECT ps_suppkey FROM partsupp WHERE ps_partkey IN (SELECT p_partkey FROM part WHERE p_retailprice > 100.00))
WHERE 
    r.rn = 1
GROUP BY 
    r.o_orderkey, r.o_orderdate, c.balance_category, ss.total_available, ss.average_cost
ORDER BY 
    r.o_orderdate DESC;
