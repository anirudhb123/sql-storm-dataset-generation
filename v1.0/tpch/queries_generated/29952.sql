WITH ranked_suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),
top_suppliers AS (
    SELECT r.r_name, rs.s_name, rs.s_acctbal
    FROM ranked_suppliers rs
    JOIN nation n ON rs.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE rs.rank <= 3
),
part_details AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, 
           ps.ps_supplycost, ps.ps_availqty,
           CONCAT(p.p_brand, ' - ', p.p_name) AS part_description
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > 50.00
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, 
           o.o_totalprice, o.o_orderdate, 
           CONCAT(c.c_name, ' ordered on ', o.o_orderdate) AS order_info
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal >= 500.00
)
SELECT ts.r_name, ts.s_name, ts.s_acctbal, 
       pd.part_description, co.order_info
FROM top_suppliers ts
JOIN part_details pd ON ts.s_acctbal > pd.ps_supplycost
JOIN customer_orders co ON ts.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = pd.p_partkey LIMIT 1)
ORDER BY ts.r_name, ts.s_name, co.o_orderdate DESC;
