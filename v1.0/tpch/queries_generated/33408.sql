WITH RECURSIVE RegionHierarchy AS (
    SELECT r_regionkey, r_name, r_comment, NULL::integer as parent_regionkey 
    FROM region
    WHERE r_regionkey = 1
    UNION ALL
    SELECT r.regionkey, r.r_name, r.r_comment, rh.r_regionkey 
    FROM region r
    JOIN RegionHierarchy rh ON r.r_nationkey = rh.r_regionkey
),
SupplierStats AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE s.s_acctbal > 10000
    GROUP BY s.s_suppkey
),
CustomerSegment AS (
    SELECT c.c_mktsegment,
           COUNT(DISTINCT c.c_custkey) AS total_customers,
           SUM(o.o_totalprice) AS total_sales
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND o.o_orderstatus = 'O'
    GROUP BY c.c_mktsegment
)
SELECT r.r_name,
       COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
       cs.total_sales,
       cs.total_customers,
       ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY cs.total_sales DESC) AS rank
FROM region r
LEFT JOIN SupplierStats ss ON r.r_regionkey = ss.s_suppkey
LEFT JOIN CustomerSegment cs ON r.r_regionkey = cs.c_mktsegment
WHERE r.r_comment IS NOT NULL OR cs.total_sales > 0
ORDER BY r.r_name, total_supply_cost DESC;
