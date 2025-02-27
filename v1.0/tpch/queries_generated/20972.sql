WITH RECURSIVE DateRange AS (
    SELECT MIN(o_orderdate) AS start_date, MAX(o_orderdate) AS end_date
    FROM orders
),
AvgShippingCost AS (
    SELECT
        l_shipmode,
        AVG(l_tax + l_supplycost) AS avg_shipping_cost
    FROM lineitem
    JOIN partsupp ON lineitem.l_partkey = partsupp.ps_partkey
    GROUP BY l_shipmode
),
CustomerNation AS (
    SELECT 
        c.c_custkey,
        n.n_name,
        c.c_mktsegment,
        COALESCE(NULLIF(c.c_address, ''), 'UNKNOWN') AS address,
        c.c_acctbal * (1 + CASE WHEN c.c_acctbal < 0 THEN -0.1 ELSE 0 END) AS adjusted_balance
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE c.c_acctbal IS NOT NULL
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        AVG(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY o.o_orderkey) AS avg_price
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'F')
), 
DistinctRegions AS (
    SELECT DISTINCT r.r_name
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    WHERE n.n_comment IS NOT NULL
),
OrderSummary AS (
    SELECT
        fo.o_orderkey,
        fo.o_orderdate,
        fn.n_name AS nation_name,
        COALESCE(MAX(asc.avg_shipping_cost) OVER (PARTITION BY fo.o_orderkey), 0) AS shipping_cost,
        COALESCE(SUM(ps.ps_supplycost), 0) AS total_supply_cost
    FROM FilteredOrders fo
    LEFT JOIN partsupp ps ON fo.o_orderkey = ps.ps_partkey
    LEFT JOIN CustomerNation cn ON cn.c_custkey = fo.o_orderkey
    LEFT JOIN AvgShippingCost asc ON RANK() OVER (PARTITION BY fo.o_orderkey ORDER BY fo.o_totalprice DESC) <= 1
    LEFT JOIN nation fn ON cn.n_name = fn.n_name
    WHERE fo.avg_price > 100.00
    GROUP BY fo.o_orderkey, fo.o_orderdate, fn.n_name
)
SELECT 
    os.o_orderkey,
    os.o_orderdate,
    COUNT(DISTINCT dr.r_name) AS distinct_region_count,
    SUM(os.total_supply_cost) AS total_supply_cost,
    SUM(os.shipping_cost) AS total_shipping_cost,
    COUNT(cn.c_custkey) FILTER (WHERE cn.adjusted_balance > 0) AS positive_balance_customers,
    CASE 
        WHEN SUM(os.total_supply_cost) IS NULL THEN 'NO COST'
        ELSE 'COST EXISTS'
    END AS cost_presence
FROM OrderSummary os
JOIN DistinctRegions dr ON os.o_orderdate BETWEEN (SELECT start_date FROM DateRange) AND (SELECT end_date FROM DateRange)
LEFT JOIN CustomerNation cn ON os.o_orderkey = cn.c_custkey
GROUP BY os.o_orderkey, os.o_orderdate
HAVING COUNT(d DISTINCT dr.r_name) > 2;
