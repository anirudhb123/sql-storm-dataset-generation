WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c1.c_acctbal) FROM customer c1)
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM customer c
    INNER JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE ch.level < 5
),
RankedOrders AS (
    SELECT 
        o.o_orderkey, o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost,
        CASE WHEN ps.ps_availqty IS NULL THEN 'Not Available' ELSE 'Available' END AS availability_status
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    INNER JOIN part p ON ps.ps_partkey = p.p_partkey
),
RecentShipments AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_shipdate >= DATEADD(month, -6, GETDATE())
    GROUP BY l.l_orderkey
)
SELECT 
    c.c_name, 
    COALESCE(r.o_totalprice, 0) AS total_ordered_price,
    COUNT(DISTINCT sp.p_partkey) AS unique_parts_supplied,
    SUM(sp.ps_supplycost) AS total_supply_cost,
    MAX(sp.availability_status) AS overall_availability,
    SUM(rs.total_revenue) AS total_recent_revenue
FROM customer c
LEFT JOIN RankedOrders r ON c.c_custkey = r.o_orderkey
LEFT JOIN SupplierPartDetails sp ON c.c_nationkey = sp.s_suppkey
LEFT JOIN RecentShipments rs ON c.c_custkey = rs.l_orderkey
WHERE c.c_mktsegment = 'BUILDING'
AND (c.c_acctbal IS NULL OR c.c_acctbal > 0)
GROUP BY c.c_custkey, c.c_name
HAVING COUNT(DISTINCT r.o_orderkey) > 1
ORDER BY total_recent_revenue DESC, c.c_name;
