WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, p.p_partkey, p.p_retailprice, ps.ps_supplycost, ps.ps_availqty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
), CustomerInfo AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
), NationInfo AS (
    SELECT n.n_nationkey, n.n_name, r.r_regionkey
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
), AggregatedData AS (
    SELECT si.s_nationkey, ci.c_nationkey AS customer_nationkey, SUM(si.ps_availqty) AS total_available_qty, COUNT(ci.o_orderkey) AS total_orders
    FROM SupplierInfo si
    JOIN CustomerInfo ci ON si.s_nationkey = ci.c_nationkey
    GROUP BY si.s_nationkey, ci.c_nationkey
)
SELECT ni.n_name AS nation_name, ad.total_available_qty, ad.total_orders
FROM AggregatedData ad
JOIN NationInfo ni ON ad.customer_nationkey = ni.n_nationkey
WHERE ad.total_orders > 0
ORDER BY ad.total_available_qty DESC, ad.total_orders DESC
LIMIT 10;
