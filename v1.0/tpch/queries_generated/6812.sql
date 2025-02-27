WITH SupplierCosts AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
AggregateData AS (
    SELECT 
        r.r_name AS region,
        n.n_name AS nation,
        SUM(CASE WHEN o.o_orderstatus = 'F' THEN l.l_extendedprice END) AS total_revenue_fully_filled,
        SUM(CASE WHEN o.o_orderstatus = 'P' THEN l.l_extendedprice END) AS total_revenue_partially_filled,
        COUNT(DISTINCT o.o_orderkey) AS total_orders_filled
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY r.r_name, n.n_name
)
SELECT 
    ad.region,
    ad.nation,
    ad.total_revenue_fully_filled,
    ad.total_revenue_partially_filled,
    ad.total_orders_filled,
    sc.s_name AS supplier_name,
    sc.total_cost
FROM AggregateData ad
JOIN SupplierCosts sc ON ad.region = (SELECT r_name FROM region WHERE r_regionkey = (SELECT n_nationkey FROM nation WHERE n_name = ad.nation))
ORDER BY ad.region, ad.nation, sc.total_cost DESC;
