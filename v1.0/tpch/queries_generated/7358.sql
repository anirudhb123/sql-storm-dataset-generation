WITH RECURSIVE nation_supplier AS (
    SELECT n.n_nationkey, n.n_name, s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE n.n_name IN ('FRANCE', 'GERMANY')
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN nation_supplier ns ON s.s_nationkey = ns.n_nationkey
    WHERE ns.n_name NOT IN ('FRANCE', 'GERMANY')
),
part_details AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_retailprice, ps.ps_availqty
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > 100.00
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 500.00 AND o.o_orderstatus = 'O'
)
SELECT ns.n_name, COUNT(DISTINCT ns.s_suppkey) AS supplier_count, 
       SUM(pd.ps_availqty) AS total_available_qty,
       COUNT(DISTINCT co.o_orderkey) AS order_count, 
       SUM(co.o_totalprice) AS total_revenue
FROM nation_supplier ns
LEFT JOIN part_details pd ON ns.n_nationkey = (
    SELECT n.n_nationkey 
    FROM nation n
    WHERE pd.p_partkey = (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_suppkey = ns.s_suppkey
    )
)
LEFT JOIN customer_orders co ON ns.n_nationkey = co.c_custkey
GROUP BY ns.n_name
HAVING SUM(pd.ps_availqty) > 1000
ORDER BY total_revenue DESC;
