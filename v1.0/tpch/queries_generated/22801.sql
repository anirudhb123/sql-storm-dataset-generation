WITH recursive part_supplier AS (
    SELECT ps_partkey, ps_suppkey, ps_availqty, ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost) as rn
    FROM partsupp
    WHERE ps_availqty > 0
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           SUM(o.o_totalprice) as total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'F') 
      AND (c.c_acctbal IS NOT NULL OR c.c_name LIKE '%VIP%')
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
),
order_line_item AS (
    SELECT l_orderkey, SUM(l_extendedprice * (1 - l_discount)) AS total_line_price
    FROM lineitem
    GROUP BY l_orderkey
)
SELECT DISTINCT p.p_partkey, p.p_name, s.s_name AS supplier_name, 
                coalesce(c.c_name, 'Unknown Customer') AS customer_name,
                CASE WHEN cl.total_line_price IS NULL THEN 0
                     ELSE cl.total_line_price END AS total_price_line,
                ps.ps_availqty, ps.ps_supplycost,
                RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) as supply_rank
FROM part p
JOIN part_supplier ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN customer_orders co ON EXISTS (
        SELECT 1 
        FROM orders o2 
        WHERE o2.o_custkey = co.c_custkey 
          AND o2.o_orderkey = (SELECT MAX(o3.o_orderkey) 
                               FROM orders o3 
                               WHERE o3.o_orderkey <= ps.ps_partkey)
      )
LEFT JOIN order_line_item cl ON cl.l_orderkey = ps.ps_partkey
WHERE (p.p_retailprice > 100 AND ps.ps_availqty < 50)
   OR (s.s_name IS NULL AND p.p_comment LIKE '%special%')
ORDER BY total_price_line DESC,
         supply_rank ASC
FETCH FIRST 100 ROWS ONLY;
