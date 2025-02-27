WITH RECURSIVE price_summary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        p.p_retailprice,
        (p.p_retailprice - ps.ps_supplycost) * ps.ps_availqty AS profit_margin,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY (p.p_retailprice - ps.ps_supplycost) DESC) as rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_supplycost IS NOT NULL
    UNION ALL
    SELECT 
        ps.ps_partkey,
        NULL,
        SUM(ps.ps_supplycost),
        NULL,
        NULL,
        SUM((p.p_retailprice - ps.ps_supplycost) * ps.ps_availqty) AS profit_margin
    FROM partsupp ps
    JOIN part p ON p.p_partkey = ps.ps_partkey
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_availqty) > 1000
)
, customer_orders AS (
    SELECT 
        c.c_name,
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) IS NOT NULL
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    AVG(COALESCE(cs.total_spent, 0)) AS avg_customer_spend,
    MAX(ps.ps_availqty) AS max_avail_qty,
    SUM(CASE WHEN COALESCE(ps.ps_supplycost, 0) < 100 THEN 1 ELSE 0 END) AS low_cost_supply_count,
    (SELECT COUNT(DISTINCT l.l_orderkey) 
     FROM lineitem l
     WHERE l.l_returnflag = 'R' AND l.l_shipdate < CURRENT_DATE) AS returns_count
FROM supplier s
JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN customer_orders cs ON s.s_nationkey = cs.c_custkey
GROUP BY n.n_name
HAVING COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY nation_name
WITH ROLLUP;
