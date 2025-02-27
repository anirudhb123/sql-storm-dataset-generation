WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_name = 'USA'
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey,
           (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey) AS part_count
    FROM supplier s
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(ol.l_extendedprice * (1 - ol.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem ol ON o.o_orderkey = ol.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
SupplierRevenue AS (
    SELECT sd.s_name, SUM(ol.l_extendedprice * (1 - ol.l_discount)) AS supplier_revenue
    FROM SupplierDetails sd
    JOIN lineitem ol ON sd.s_suppkey = ol.l_suppkey
    JOIN orders o ON ol.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY sd.s_name
)
SELECT r.r_name, COUNT(DISTINCT nc.n_nationkey) AS nation_count, 
       COALESCE(SUM(tr.total_revenue), 0) AS total_order_revenue,
       COALESCE(SUM(sr.supplier_revenue), 0) AS total_supplier_revenue,
       (SELECT COUNT(*) FROM TopCustomers) AS num_top_customers
FROM region r
LEFT JOIN nation nc ON r.r_regionkey = nc.n_regionkey
LEFT JOIN OrderSummary tr ON tr.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'F')
LEFT JOIN SupplierRevenue sr ON sr.supplier_revenue > 50000
GROUP BY r.r_name
ORDER BY nation_count DESC, total_order_revenue DESC;
