WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, 
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
), SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), LineitemSummary AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
    GROUP BY l.l_orderkey
), CustomerStats AS (
    SELECT c.c_custkey, c.c_name,
           SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey AND o.o_orderstatus = 'F'
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    coalesce(r.o_orderkey, ls.l_orderkey) AS order_id,
    cs.c_name AS customer_name,
    ss.s_name AS supplier_name,
    r.order_rank,
    ls.total_revenue,
    cs.total_spent,
    ss.total_supply_cost,
    CASE 
        WHEN cs.order_count > 5 THEN 'Frequent Shopper'
        ELSE 'Occasional Shopper'
    END AS shopper_type
FROM RankedOrders r
FULL OUTER JOIN LineitemSummary ls ON r.o_orderkey = ls.l_orderkey
JOIN CustomerStats cs ON cs.total_spent > 500 
    AND (cs.c_custkey NOT IN (SELECT c.c_custkey FROM customer c WHERE c.c_acctbal < 100))
LEFT JOIN SupplierInfo ss ON ss.total_supply_cost = (
        SELECT MAX(total_supply_cost) FROM SupplierInfo
    ) OR ss.total_supply_cost IS NULL
WHERE r.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
  AND (ls.total_revenue IS NOT NULL OR r.order_rank <= 10)
ORDER BY order_id DESC NULLS LAST;
