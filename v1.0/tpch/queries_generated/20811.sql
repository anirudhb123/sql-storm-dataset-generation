WITH RECURSIVE part_supply AS (
    SELECT ps_partkey, ps_suppkey, ps_availqty, ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost) as supply_rank
    FROM partsupp
    WHERE ps_availqty > (SELECT AVG(ps_availqty) FROM partsupp)
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent, 
           COUNT(o.o_orderkey) AS order_count, 
           RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank_spender
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
    GROUP BY c.c_custkey, c.c_name
),
nation_summary AS (
    SELECT n.n_regionkey, COUNT(DISTINCT n.n_nationkey) AS nation_count,
           SUM(s.s_acctbal) AS total_balance
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_regionkey
),
ordered_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS part_rank
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
)
SELECT DISTINCT 
    p.p_partkey, p.p_name, ps.ps_supplycost, 
    co.total_spent, co.order_count,
    ns.nation_count, ns.total_balance,
    (CASE 
        WHEN co.rank_spender <= 10 THEN 'Top Spender'
        ELSE 'Regular Customer'
     END) AS customer_category,
    (CASE 
        WHEN ps.ps_supplycost IS NULL THEN 'No Supply Cost'
        WHEN ps.ps_supplycost < 100 THEN 'Low Cost Supplier'
        ELSE 'High Cost Supplier'
     END) AS supply_cost_category
FROM ordered_parts p
JOIN part_supply ps ON p.p_partkey = ps.ps_partkey AND ps.supply_rank = 1
LEFT JOIN customer_orders co ON co.total_spent IS NOT NULL
LEFT JOIN nation_summary ns ON ns.n_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (SELECT MIN(nation.n_nationkey) FROM nation nation))
WHERE p.part_rank <= 5
ORDER BY co.order_count DESC NULLS LAST, p.p_retailprice ASC;
