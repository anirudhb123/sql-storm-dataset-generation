WITH RankedSuppliers AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM supplier AS s
    JOIN partsupp AS ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
HighValueCustomers AS (
    SELECT c.c_custkey,
           c.c_name,
           SUM(o.o_totalprice) AS total_order_value
    FROM customer AS c
    LEFT JOIN orders AS o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'P') OR o.o_orderstatus IS NULL
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) IS NOT NULL AND SUM(o.o_totalprice) > (SELECT AVG(o1.o_totalprice) FROM orders AS o1)
),
NationSummary AS (
    SELECT n.n_nationkey,
           n.n_name,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM nation AS n
    LEFT JOIN supplier AS s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN customer AS c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT ns.n_name,
       COALESCE(ROUND(AVG(h.total_order_value), 2), 0) AS avg_customer_order_value,
       COALESCE(MAX(rs.total_supply_cost), 0) AS max_supplier_cost,
       ns.supplier_count,
       ns.customer_count,
       CASE WHEN ns.supplier_count > 0 AND ns.customer_count > 0 THEN 'Balanced' 
            ELSE 'Unbalanced' END AS supply_customer_balance
FROM NationSummary AS ns
LEFT JOIN HighValueCustomers AS h ON ns.customer_count > 10
LEFT JOIN RankedSuppliers AS rs ON ns.n_nationkey = rs.s_nationkey AND rs.rn = 1
GROUP BY ns.n_name, ns.supplier_count, ns.customer_count
HAVING COALESCE(MAX(rs.total_supply_cost), 0) > 1000
ORDER BY ns.n_name DESC NULLS LAST;
