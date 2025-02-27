WITH RECURSIVE RegionHierarchy AS (
    SELECT r_regionkey, r_name, NULL::integer AS parent_regionkey 
    FROM region 
    WHERE r_name = 'ASIA'
    UNION ALL
    SELECT r.regionkey, r.r_name, rh.r_regionkey 
    FROM region r
    JOIN RegionHierarchy rh ON r.n_regionkey = rh.r_regionkey
),
TopSuppliers AS (
    SELECT ps.ps_suppkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY ps.ps_suppkey
),
CustomerOrders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c 
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey 
    GROUP BY c.c_custkey
),
FilteredSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_phone, s.s_acctbal, COALESCE(th.total_revenue, 0) AS total_revenue
    FROM supplier s
    LEFT JOIN TopSuppliers th ON s.s_suppkey = th.ps_suppkey
    WHERE s.s_acctbal > 5000
),
RankedCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, co.order_count, co.total_spent,
           RANK() OVER (ORDER BY co.total_spent DESC) AS spending_rank
    FROM customerOrders co
    JOIN customer c ON co.c_custkey = c.c_custkey
)
SELECT rh.r_name, fs.s_name, fs.total_revenue, rc.c_name, rc.total_spent
FROM RegionHierarchy rh
LEFT JOIN FilteredSuppliers fs ON fs.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_type = 'type1'))
JOIN RankedCustomers rc ON rc.order_count > 10
WHERE fs.total_revenue > (SELECT AVG(total_revenue) FROM TopSuppliers)
ORDER BY rh.r_name, fs.total_revenue DESC;
