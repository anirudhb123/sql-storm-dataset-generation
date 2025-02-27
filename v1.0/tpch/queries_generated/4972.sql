WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS price_rank,
        c.c_name,
        c.c_nationkey
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2023-01-01'
),
NationStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
MaxRevenue AS (
    SELECT 
        ns.n_nationkey,
        ns.total_revenue,
        RANK() OVER (ORDER BY ns.total_revenue DESC) AS revenue_rank
    FROM 
        NationStats ns
)
SELECT 
    ns.n_name,
    ns.order_count,
    CASE 
        WHEN ns.total_revenue IS NULL THEN 'No Revenue'
        ELSE TO_CHAR(ns.total_revenue, 'FM$999,999,999.00')
    END AS formatted_revenue,
    ro.o_orderkey,
    ro.price_rank,
    ro.o_orderdate
FROM 
    NationStats ns
FULL OUTER JOIN 
    RankedOrders ro ON ns.n_nationkey = ro.c_nationkey
WHERE 
    ro.price_rank = 1 OR (ro.price_rank IS NULL AND ns.order_count > 0)
ORDER BY 
    ns.n_name, ro.o_orderdate DESC NULLS LAST;
