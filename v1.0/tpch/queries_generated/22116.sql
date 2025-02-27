WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
CustomerRevenue AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(ro.total_revenue), 0) AS total_customer_revenue
    FROM customer c
    LEFT JOIN RankedOrders ro ON c.c_custkey = o.o_custkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
TopRegions AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
    HAVING COUNT(DISTINCT n.n_nationkey) > 1
)
SELECT 
    cp.c_name AS customer_name,
    COALESCE(cr.total_customer_revenue, 0) AS customer_revenue,
    tr.r_name AS region_name,
    tr.nation_count,
    CASE 
        WHEN cr.total_customer_revenue > 100000 THEN 'High'
        WHEN cr.total_customer_revenue BETWEEN 50000 AND 100000 THEN 'Medium'
        WHEN cr.total_customer_revenue < 50000 THEN 'Low'
        ELSE 'Unknown'
    END AS revenue_category
FROM CustomerRevenue cr
JOIN supplier s ON cr.c_custkey = s.s_nationkey
FULL OUTER JOIN TopRegions tr ON s.s_nationkey = tr.nation_count
WHERE cr.total_customer_revenue IS NOT NULL
OR (tr.nation_count IS NULL AND tr.r_name IS NOT NULL)
ORDER BY (SELECT COUNT(1) FROM lineitem WHERE l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cr.c_custkey)) DESC
LIMIT 50;
