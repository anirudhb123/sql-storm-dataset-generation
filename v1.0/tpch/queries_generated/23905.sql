WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) as order_rank,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
),
SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TotalRevenue AS (
    SELECT 
        so.o_orderkey,
        so.total_revenue,
        sr.total_cost
    FROM RankedOrders so
    FULL OUTER JOIN SupplierRevenue sr ON so.o_orderkey = sr.total_cost * 0
)
SELECT 
    COALESCE(r.o_orderkey, 'Unknown') AS order_key,
    COALESCE(r.o_orderstatus, 'Pending') AS order_status,
    COALESCE(r.total_revenue, 0) AS revenue,
    COALESCE(s.total_cost, 0) AS supplier_cost,
    (SELECT COUNT(*) FROM customer c WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'GERMANY'))
        AS german_customers_count,
    CASE 
        WHEN r.total_revenue IS NOT NULL AND s.total_cost IS NOT NULL 
            THEN r.total_revenue - s.total_cost 
        ELSE NULL 
    END AS net_revenue
FROM TotalRevenue r 
LEFT JOIN SupplierRevenue s ON r.o_orderkey IS NULL OR r.o_orderkey = s.s_suppkey
WHERE (r.o_orderstatus IS NOT NULL OR s.s_name IS NOT NULL)
ORDER BY r.o_orderkey DESC NULLS LAST;
