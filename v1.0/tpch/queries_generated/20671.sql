WITH RECURSIVE customer_orders AS (
    SELECT c.c_custkey, c.c_name, 
           SUM(o.o_totalprice) AS total_spent,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS spend_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),
high_spenders AS (
    SELECT c.n_nationkey, SUM(co.total_spent) AS national_spending
    FROM nation c
    JOIN customer_orders co ON c.n_nationkey = co.c_nationkey
    WHERE co.spend_rank <= 5
    GROUP BY c.n_nationkey
),
supplier_part AS (
    SELECT ps.ps_partkey, s.s_acctbal,
           COUNT(DISTINCT s.s_suppkey) OVER (PARTITION BY ps.ps_partkey) AS supplier_count,
           STRING_AGG(DISTINCT s.s_name, ', ') OVER (PARTITION BY ps.ps_partkey) AS supplier_names
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
significant_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           COALESCE(MAX(l.l_extendedprice) * 0.9, 0) AS max_discounted_price,
           SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS return_count
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
    HAVING COUNT(l.l_orderkey) > 5 AND MAX(l.l_discount) IS NULL
)
SELECT sp.p_partkey, sp.p_name, sp.p_retailprice, sp.max_discounted_price,
       COALESCE(sp.return_count, 0) AS returns,
       hs.national_spending, 
       s.supplier_count, s.supplier_names
FROM significant_parts sp
LEFT JOIN high_spenders hs ON sp.p_retailprice > hs.national_spending
LEFT JOIN supplier_part s ON sp.p_partkey = s.ps_partkey
WHERE s.supplier_count > 2 OR sp.return_count > 0
ORDER BY sp.p_partkey
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
