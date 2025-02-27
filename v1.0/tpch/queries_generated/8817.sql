WITH SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
),
LineItemsSummary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
),
NationSupplier AS (
    SELECT n.n_name, SUM(sp.ps_supplycost * sp.ps_availqty) AS total_cost
    FROM SupplierParts sp
    JOIN supplier s ON sp.s_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY n.n_name
),
FinalReport AS (
    SELECT c.c_name AS customer_name, co.o_orderkey, co.o_totalprice, ls.revenue, ns.n_name AS supplier_nation, ns.total_cost
    FROM CustomerOrders co
    LEFT JOIN LineItemsSummary ls ON co.o_orderkey = ls.l_orderkey
    LEFT JOIN NationSupplier ns ON ns.total_cost IS NOT NULL
)
SELECT customer_name, o_orderkey, o_totalprice, revenue, supplier_nation, total_cost
FROM FinalReport
WHERE revenue > 1000
ORDER BY customer_name, o_totalprice DESC;
