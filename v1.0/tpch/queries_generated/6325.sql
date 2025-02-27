WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_availqty) AS total_availqty, SUM(ps.ps_supplycost) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
NationDetails AS (
    SELECT n.n_nationkey, n.n_name, r.r_regionkey
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
LineItemSummary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value, MAX(l.l_shipdate) AS latest_ship_date
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    sd.s_suppkey,
    sd.s_name,
    nd.n_name AS supplier_nation,
    co.c_custkey,
    co.c_name AS customer_name,
    co.order_count,
    co.total_spent,
    lis.total_value AS order_value,
    lis.latest_ship_date
FROM SupplierDetails sd
JOIN NationDetails nd ON sd.s_nationkey = nd.n_nationkey
JOIN LineItemSummary lis ON lis.l_orderkey IN (SELECT o.o_orderkey FROM orders o JOIN customer c ON o.o_custkey = c.c_custkey WHERE c.c_nationkey = nd.n_nationkey)
JOIN CustomerOrders co ON co.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_suppkey = sd.s_suppkey LIMIT 1))
WHERE sd.total_supplycost > 10000
ORDER BY sd.s_name, co.total_spent DESC
LIMIT 50;
