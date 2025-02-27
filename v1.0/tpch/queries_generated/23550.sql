WITH RECURSIVE price_ranks AS (
    SELECT 
        ps_partkey,
        ps_suppkey,
        ps_supplycost,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost ASC) as rank_order
    FROM partsupp
),
order_summaries AS (
    SELECT 
        o_custkey,
        COUNT(o_orderkey) AS order_count,
        SUM(o_totalprice) AS total_spent
    FROM orders
    WHERE o_orderstatus = 'O'
    GROUP BY o_custkey
),
customer_details AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal,
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) as cust_rank
    FROM customer c 
    JOIN nation n ON c.c_nationkey = n.n_nationkey
),
part_supplier_counts AS (
    SELECT 
        p1.p_partkey,
        COUNT(DISTINCT ps.s_suppkey) AS supplier_count
    FROM part p1 
    LEFT JOIN partsupp ps ON p1.p_partkey = ps.ps_partkey
    GROUP BY p1.p_partkey
)
SELECT 
    pd.cust_rank,
    pd.nation_name,
    pd.c_name,
    pd.c_acctbal,
    p.p_name,
    ps.ps_supplycost,
    (CASE 
        WHEN ps.ps_supplycost IS NULL THEN 'Unavailable'
        ELSE FORMAT(ps.ps_supplycost, 'C')
    END) AS formatted_cost,
    r.order_count,
    r.total_spent,
    s.s_name AS supplier_name,
    COALESCE(l.l_returnflag, 'N') AS return_status,
    COUNT(DISTINCT l.l_orderkey) FILTER (WHERE l.l_returnflag = 'R') AS returned_orders
FROM customer_details pd
LEFT JOIN order_summaries r ON pd.c_custkey = r.o_custkey
JOIN price_ranks ps ON pd.c_custkey = ps.ps_suppkey
JOIN part_supplier_counts p ON ps.ps_partkey = p.p_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN lineitem l ON l.l_suppkey = s.s_suppkey AND l.l_orderkey IN (SELECT o_orderkey FROM orders WHERE o_custkey = pd.c_custkey)
WHERE pd.c_acctbal > 5000.00
    AND (p.supplier_count > 2 OR ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp) * 0.8)
ORDER BY pd.cust_rank, total_spent DESC
LIMIT 100;
