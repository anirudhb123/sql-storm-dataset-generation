
WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_availqty) AS total_available
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderstatus, o.o_orderdate, o.o_totalprice
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '1997-01-01'
),
OrderLineAmounts AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_amount
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY o.o_orderkey
),
NationRegion AS (
    SELECT n.n_name, r.r_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name, r.r_name
)
SELECT 
    co.c_name AS customer_name,
    COALESCE(SUM(ola.total_line_amount), 0) AS total_spent,
    si.total_available AS supplier_availability,
    nr.n_name AS nation_name,
    nr.r_name AS region_name
FROM CustomerOrders co
LEFT JOIN OrderLineAmounts ola ON co.o_orderkey = ola.o_orderkey
LEFT JOIN SupplierInfo si ON si.s_nationkey = co.c_custkey
JOIN NationRegion nr ON nr.n_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = co.c_custkey)
GROUP BY co.c_name, si.total_available, nr.n_name, nr.r_name
HAVING COALESCE(SUM(ola.total_line_amount), 0) > 1000 OR si.total_available IS NULL
ORDER BY total_spent DESC, co.c_name;
