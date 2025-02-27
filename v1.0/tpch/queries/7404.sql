WITH nation_summary AS (
    SELECT n.n_name AS nation_name,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(s.s_acctbal) AS total_account_balance,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_name
),
order_summary AS (
    SELECT c.c_nationkey,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_nationkey
),
combined_summary AS (
    SELECT ns.nation_name,
           os.order_count,
           os.total_order_value,
           ns.supplier_count,
           ns.total_account_balance,
           ns.total_supply_cost
    FROM nation_summary ns
    LEFT JOIN order_summary os ON ns.nation_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = os.c_nationkey)
)
SELECT cs.nation_name,
       cs.order_count,
       cs.total_order_value,
       cs.supplier_count,
       cs.total_account_balance,
       cs.total_supply_cost,
       (CASE 
            WHEN cs.total_order_value > 0 THEN (cs.total_supply_cost / cs.total_order_value) * 100 
            ELSE 0
        END) AS supply_cost_ratio
FROM combined_summary cs
WHERE cs.total_order_value > 50000
ORDER BY cs.total_supply_cost DESC;
