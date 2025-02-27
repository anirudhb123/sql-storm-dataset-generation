WITH SupplierSummary AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, COUNT(ps.ps_partkey) AS part_count, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
),
OrderLineSummary AS (
    SELECT lo.l_orderkey, SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_line_value
    FROM lineitem lo
    GROUP BY lo.l_orderkey
)
SELECT SS.s_suppkey, SS.s_name, SS.part_count, SS.total_supply_value, CO.c_custkey, CO.c_name, CO.order_count, CO.total_spent, OLS.total_line_value
FROM SupplierSummary SS
JOIN CustomerOrders CO ON SS.part_count > 5 AND CO.order_count > 10
JOIN OrderLineSummary OLS ON CO.order_count = OLS.total_line_value / (CO.total_spent / CO.order_count)
WHERE SS.total_supply_value > 10000
ORDER BY SS.total_supply_value DESC, CO.total_spent DESC
LIMIT 50;
