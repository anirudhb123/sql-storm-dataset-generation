WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O'
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        r.r_name AS region_name,
        COALESCE(su.total_avail_qty, 0) AS total_avail_qty,
        COALESCE(su.avg_supply_cost, 0) AS avg_supply_cost
    FROM part p
    LEFT JOIN SupplierAvailability su ON p.p_partkey = su.ps_partkey
    JOIN supplier s ON su.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    pd.p_name, 
    pd.p_brand, 
    pd.region_name,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    SUM(ro.o_totalprice) AS total_revenue,
    AVG(pd.p_retailprice) AS avg_retail_price,
    MAX(pa.total_avail_qty) AS max_avail_qty,
    STRING_AGG(DISTINCT c.c_name, '; ') AS customer_names
FROM PartDetails pd
LEFT JOIN RankedOrders ro ON pd.p_partkey = (
    SELECT l.l_partkey 
    FROM lineitem l 
    WHERE l.l_orderkey = ro.o_orderkey
    LIMIT 1
)
LEFT JOIN customer c ON ro.o_custkey = c.c_custkey
WHERE pd.total_avail_qty > 0 AND ro.order_rank <= 10
GROUP BY pd.p_name, pd.p_brand, pd.region_name
HAVING SUM(ro.o_totalprice) > 10000
ORDER BY total_revenue DESC;
