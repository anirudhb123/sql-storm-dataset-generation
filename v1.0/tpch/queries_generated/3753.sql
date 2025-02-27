WITH SupplierPartSummary AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(ps.ps_availqty) AS total_available,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrderSummary AS (
    SELECT c.c_custkey,
           c.c_name,
           COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
MaxOrderSummary AS (
    SELECT c.c_custkey,
           MAX(o.o_totalprice) AS max_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
NationRegionSummary AS (
    SELECT n.n_nationkey,
           n.n_name,
           r.r_name AS region_name,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_nationkey, n.n_name, r.r_name
)
SELECT p.p_name,
       p.p_retailprice,
       COALESCE(avg_supply.total_available, 0) AS avg_supply_qty,
       COALESCE(cus_order.total_orders, 0) AS total_orders,
       max_ord.max_order_value,
       n_region.region_name,
       n_region.supplier_count
FROM part p
LEFT JOIN SupplierPartSummary avg_supply ON p.p_partkey IN (
    SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s)
)
LEFT JOIN CustomerOrderSummary cus_order ON p.p_partkey IN (
    SELECT l.l_partkey FROM lineitem l JOIN orders o ON l.l_orderkey = o.o_orderkey WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c)
)
LEFT JOIN MaxOrderSummary max_ord ON cus_order.c_custkey = max_ord.c_custkey
LEFT JOIN NationRegionSummary n_region ON EXISTS (
    SELECT 1 FROM supplier s WHERE s.s_suppkey = ANY(SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey)
)
WHERE p.p_retailprice > (
    SELECT AVG(p2.p_retailprice)
    FROM part p2
    WHERE p2.p_size = p.p_size AND p2.p_partkey <> p.p_partkey
)
ORDER BY n_region.region_name, p.p_name;
