WITH RecentOrders AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice
    FROM orders
    WHERE o_orderdate >= DATEADD(month, -6, GETDATE())
),
HighValueCustomers AS (
    SELECT c_custkey, c_name, c_acctbal
    FROM customer
    WHERE c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
),
PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
LineItemSummary AS (
    SELECT l_orderkey, COUNT(*) AS item_count, SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
    FROM lineitem
    GROUP BY l_orderkey
)
SELECT 
    r.r_name AS region,
    nc.n_name AS nation,
    hc.c_name AS customer_name,
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    psi.p_name AS part_name,
    psi.total_supplycost,
    lis.item_count,
    lis.total_revenue
FROM RecentOrders ro
JOIN HighValueCustomers hc ON ro.o_custkey = hc.c_custkey
JOIN nation nc ON hc.c_nationkey = nc.n_nationkey
JOIN region r ON nc.n_regionkey = r.r_regionkey
JOIN LineItemSummary lis ON ro.o_orderkey = lis.l_orderkey
JOIN PartSupplierInfo psi ON LIS.total_revenue > psi.total_supplycost
WHERE ro.o_totalprice > (SELECT AVG(o_totalprice) FROM orders) 
ORDER BY ro.o_orderdate DESC, hc.c_acctbal DESC;
