WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank,
        c.c_nationkey
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate BETWEEN '1995-01-01' AND '1996-12-31'
),
supplier_summary AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        MIN(s.s_acctbal) AS min_acct_bal,
        MAX(s.s_acctbal) AS max_acct_bal
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    r.r_name,
    p.p_name,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS orders_count,
    COUNT(DISTINCT s.s_suppkey) FILTER (WHERE s.s_acctbal > 50000) AS high_balance_suppliers,
    AVG(su.total_supply_cost) OVER (PARTITION BY r.r_name) AS avg_supply_cost,
    CASE 
        WHEN EXISTS (SELECT 1 FROM ranked_orders ro WHERE ro.o_orderkey = o.o_orderkey AND ro.order_rank <= 10) THEN 'Top Order'
        ELSE 'Regular Order'
    END AS order_type
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN ranked_orders o ON o.o_orderkey = l.l_orderkey
WHERE p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100.00)
GROUP BY r.r_name, p.p_name
HAVING SUM(l.l_discount) IS NULL OR SUM(l.l_discount) < 0.1
ORDER BY total_revenue DESC, r.r_name NULLS LAST, p.p_name ASC;
