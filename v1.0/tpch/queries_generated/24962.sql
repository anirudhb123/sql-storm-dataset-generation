WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) as rank
    FROM customer c
), 
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
), 
ActiveOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_extendedprice
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
), 
RecentShipments AS (
    SELECT
        l.l_orderkey,
        DATEDIFF(CURRENT_DATE, l.l_shipdate) AS days_since_shipment,
        SUM(l.l_quantity) AS total_quantity
    FROM lineitem l
    WHERE l.l_returnflag = 'R' OR l.l_linestatus = 'F'
    GROUP BY l.l_orderkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT rc.c_custkey) AS high_value_customers,
    SUM(sp.total_supplycost) AS total_cost_of_parts,
    AVG(a.total_extendedprice) AS avg_order_value,
    COALESCE(MAX(rs.days_since_shipment), 0) AS max_days_since_shipment
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN RankedCustomers rc ON n.n_nationkey = rc.c_nationkey AND rc.rank <= 5
LEFT JOIN SupplierParts sp ON n.n_nationkey = (
    SELECT n2.n_nationkey 
    FROM supplier s2 
    JOIN partsupp ps2 ON s2.s_suppkey = ps2.ps_suppkey 
    JOIN nation n2 ON s2.s_nationkey = n2.n_nationkey 
    WHERE s2.s_suppkey = sp.s_suppkey
    LIMIT 1
)
LEFT JOIN ActiveOrders a ON rc.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = a.o_orderkey)
LEFT JOIN RecentShipments rs ON a.o_orderkey = rs.l_orderkey
WHERE rc.c_acctbal IS NOT NULL AND rc.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_nationkey = n.n_nationkey)
GROUP BY r.r_name
HAVING COUNT(DISTINCT rc.c_custkey) > 0 AND AVG(a.total_extendedprice) IS NOT NULL
ORDER BY r.r_name;
