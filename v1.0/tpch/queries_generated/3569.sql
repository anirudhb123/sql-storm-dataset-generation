WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS customer_rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000.00
),
ShippedLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM lineitem l
    WHERE l.l_shipdate < CURRENT_DATE
    GROUP BY l.l_orderkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(ss.total_avail_qty, 0) AS total_avail_qty,
    COALESCE(ss.avg_supply_cost, 0.00) AS avg_supply_cost,
    COALESCE(hlc.c_name, 'Unknown') AS customer_name,
    COALESCE(hlc.c_acctbal, 0.00) AS customer_acctbal,
    rh.o_orderdate,
    rh.o_orderkey,
    sh.net_revenue
FROM part p
LEFT JOIN SupplierSummary ss ON ss.s_suppkey IN (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    WHERE ps.ps_partkey = p.p_partkey
)
LEFT JOIN HighValueCustomers hlc ON hlc.c_custkey IN (
    SELECT o.o_custkey 
    FROM RankedOrders o 
    WHERE o.o_orderkey IN (
        SELECT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_partkey = p.p_partkey
    )
)
LEFT JOIN RankedOrders rh ON rh.o_orderkey = hlc.c_custkey
LEFT JOIN ShippedLineItems sh ON sh.l_orderkey = rh.o_orderkey
WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) 
AND p.p_size BETWEEN 10 AND 20
ORDER BY p.p_partkey, rh.o_orderdate DESC;
