WITH RECURSIVE cust_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate, 
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('F', 'O') AND c.c_acctbal IS NOT NULL
), ranked_orders AS (
    SELECT co.*, SUM(co.o_totalprice) OVER (PARTITION BY co.c_custkey) AS total_spent
    FROM cust_orders co
), supplier_part_data AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_brand, p.p_retailprice, 
           COALESCE(SUM(ps.ps_supplycost), 0) AS total_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, p.p_partkey, p.p_brand, p.p_retailprice
), aggregated_data AS (
    SELECT r.c_custkey, r.c_name, r.o_orderkey, r.o_totalprice, r.o_orderdate, 
           r.total_spent, sp.p_partkey, sp.p_brand, sp.total_supply_cost,
           RANK() OVER (PARTITION BY r.c_custkey ORDER BY r.o_totalprice DESC) AS price_rank
    FROM ranked_orders r
    JOIN supplier_part_data sp ON r.o_orderkey % 5 = sp.p_partkey % 5
    WHERE r.o_totalprice > (SELECT AVG(o_totalprice) FROM ranked_orders) 
      AND sp.total_supply_cost IS NOT NULL
)
SELECT ad.c_name, ad.o_orderdate, ad.p_brand, ad.total_spent, 
       CASE 
           WHEN ad.price_rank = 1 THEN 'Highest Spending'
           WHEN ad.price_rank <= 3 THEN 'Top 3 Spend'
           ELSE 'Other'
       END AS spending_category
FROM aggregated_data ad
WHERE ad.o_orderdate BETWEEN DATEADD(MONTH, -6, CURRENT_DATE) AND CURRENT_DATE
  AND ad.total_spent > (SELECT AVG(total_spent) FROM aggregated_data) 
ORDER BY ad.total_spent DESC, ad.o_orderdate ASC;
