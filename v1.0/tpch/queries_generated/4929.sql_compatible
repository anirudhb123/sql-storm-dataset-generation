
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O'
),
SupplierAvailability AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
CustomerNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS total_customers
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.c_name,
    sa.total_avail_qty,
    sa.avg_supply_cost,
    cn.n_name,
    cn.total_customers
FROM RankedOrders ro
LEFT JOIN SupplierAvailability sa ON sa.p_partkey IN (
    SELECT ps.ps_partkey 
    FROM lineitem li 
    JOIN partsupp ps ON li.l_partkey = ps.ps_partkey 
    WHERE li.l_orderkey = ro.o_orderkey
)
LEFT JOIN CustomerNations cn ON ro.c_name LIKE CONCAT('%', cn.n_name, '%')
WHERE ro.rn <= 5
ORDER BY ro.o_orderdate DESC, ro.o_totalprice DESC;
