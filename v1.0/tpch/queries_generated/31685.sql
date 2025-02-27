WITH RECURSIVE RegionHierarchy AS (
    SELECT r_regionkey, r_name, r_comment, 0 AS level
    FROM region
    WHERE r_regionkey = 1
    UNION ALL
    SELECT r.r_regionkey, r.r_name, r.r_comment, rh.level + 1
    FROM region r
    JOIN RegionHierarchy rh ON r.r_regionkey = rh.r_regionkey + 1
),
TopSuppliers AS (
    SELECT s_nationkey, s_suppkey, s_name, s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rn
    FROM supplier
    WHERE s_acctbal IS NOT NULL
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey,
           SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),
OrderLineItems AS (
    SELECT ol.l_orderkey, SUM(ol.l_extendedprice * (1 - ol.l_discount)) AS revenue
    FROM lineitem ol
    WHERE ol.l_shipdate > CURRENT_DATE - INTERVAL '1' YEAR
    GROUP BY ol.l_orderkey
)
SELECT 
    rh.r_name AS region_name,
    ns.n_name AS nation_name,
    ts.s_name AS supplier_name,
    co.c_name AS customer_name,
    co.total_spent,
    ol.revenue,
    CASE 
        WHEN co.total_spent > 10000 THEN 'High Value'
        ELSE 'Regular'
    END AS customer_type
FROM region r
LEFT JOIN nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN TopSuppliers ts ON ns.n_nationkey = ts.s_nationkey AND ts.rn <= 5
LEFT JOIN CustomerOrders co ON ts.suppkey = co.c_custkey
LEFT JOIN OrderLineItems ol ON co.c_custkey = ol.l_orderkey
WHERE ts.sacctbal IS NOT NULL OR co.total_spent IS NOT NULL
ORDER BY rh.level, region_name, nation_name, supplier_name, customer_name;
