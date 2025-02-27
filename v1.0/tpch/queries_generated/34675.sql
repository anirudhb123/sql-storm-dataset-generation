WITH RECURSIVE parts_cost AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    UNION ALL
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) + pc.total_cost
    FROM parts_cost pc
    JOIN part p ON pc.p_partkey = p.p_partkey
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE pc.total_cost IS NOT NULL
    GROUP BY p.p_partkey, p.p_name
),
customer_order_summary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS rn
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) IS NOT NULL
),
supplier_details AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           COALESCE(NULLIF(s.s_acctbal, 0), NULL) AS effective_acctbal,
           DENSE_RANK() OVER (ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
)
SELECT cs.c_name, COALESCE(pc.p_name, 'N/A') AS part_name,
       cs.total_spent, pc.total_cost, sd.s_name, sd.effective_acctbal
FROM customer_order_summary cs
FULL OUTER JOIN parts_cost pc ON cs.order_count >= 1
LEFT JOIN supplier_details sd ON sd.rank <= 10
WHERE (cs.total_spent > 1000 OR pc.total_cost > 500)
  AND cs.rn = 1
ORDER BY cs.total_spent DESC, pc.total_cost DESC;
