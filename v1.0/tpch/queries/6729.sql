WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        SUM(li.l_quantity) AS total_quantity,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS net_revenue
    FROM RankedOrders ro
    JOIN lineitem li ON ro.o_orderkey = li.l_orderkey
    WHERE ro.price_rank <= 100
    GROUP BY ro.o_orderkey, ro.o_orderdate, ro.o_totalprice
),
SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
),
RegionRevenue AS (
    SELECT 
        n.n_nationkey,
        SUM(sr.total_sales) AS total_sales_by_region
    FROM nation n
    JOIN SupplierRevenue sr ON n.n_nationkey = (SELECT s_nationkey FROM supplier WHERE s_suppkey = sr.s_suppkey)
    GROUP BY n.n_nationkey
)
SELECT 
    n.n_name,
    rr.total_sales_by_region,
    COUNT(DISTINCT ho.o_orderkey) AS high_order_count
FROM RegionRevenue rr
JOIN nation n ON rr.n_nationkey = n.n_nationkey
LEFT JOIN HighValueOrders ho ON ho.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY n.n_name, rr.total_sales_by_region
ORDER BY rr.total_sales_by_region DESC, high_order_count DESC;