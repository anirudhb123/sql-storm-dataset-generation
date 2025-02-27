WITH RECURSIVE nation_supplier AS (
    SELECT n.n_nationkey, n.n_name, s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE n.n_name like 'A%'
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment
    FROM nation_supplier ns
    JOIN nation n ON ns.n_nationkey = n.n_nationkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE n.n_name like 'B%'
),

part_supplier_info AS (
    SELECT p.p_partkey, p.p_brand, p.p_type, ps.ps_availqty, ps.ps_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > 100.00
),

customer_order_summary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 5000.00
    GROUP BY c.c_custkey, c.c_name
)

SELECT n.n_name, COUNT(DISTINCT n.s_suppkey) AS supplier_count, 
       SUM(p.ps_supplycost * p.ps_availqty) AS total_supply_cost,
       SUM(c.total_spent) AS total_customer_spending
FROM nation_supplier n
JOIN part_supplier_info p ON n.s_suppkey = p.ps_suppkey
JOIN customer_order_summary c ON c.c_custkey = n.s_suppkey
GROUP BY n.n_name
HAVING COUNT(DISTINCT n.s_suppkey) > 5
ORDER BY total_customer_spending DESC;
