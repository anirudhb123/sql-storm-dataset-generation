WITH RECURSIVE customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderstatus, o.o_totalprice
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IS NOT NULL
    UNION ALL
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderstatus, o.o_totalprice
    FROM customer_orders co
    JOIN orders o ON co.c_custkey = o.o_custkey
    WHERE co.o_orderstatus = 'F'
      AND o.o_orderkey > co.o_orderkey
),
part_supplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty,
           RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) as rank
    FROM partsupp ps
    WHERE ps.ps_availqty IS NOT NULL
),
supply_info AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           COALESCE(AVG(l.l_extendedprice * (1 - l.l_discount)), 0) as avg_supply_price
    FROM supplier s
    LEFT JOIN lineitem l ON s.s_suppkey = l.l_suppkey
    WHERE l.l_returnflag = 'N' AND l.l_discount IS NOT NULL
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
region_details AS (
    SELECT n.n_name, r.r_name, COUNT(DISTINCT s.s_suppkey) AS num_suppliers
    FROM nation n 
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name, r.r_name
    HAVING COUNT(s.s_suppkey) > 1
)
SELECT co.c_name, p.p_name, ps.ps_availqty,
       si.s_name, si.avg_supply_price,
       rd.r_name,
       (CASE 
           WHEN co.o_totalprice IS NULL THEN 'No Orders Yet'
           WHEN co.o_totalprice > 10000 THEN 'High Value Customer'
           ELSE 'Regular Customer'
        END) as customer_category
FROM customer_orders co
INNER JOIN part_supplier ps ON co.o_orderkey = ps.ps_partkey
INNER JOIN supply_info si ON ps.ps_suppkey = si.s_suppkey
LEFT JOIN region_details rd ON si.s_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = rd.n_name))
WHERE co.o_orderstatus IN ('O', 'F') 
  AND (si.avg_supply_price IS NOT NULL OR si.s_acctbal > 50000)
ORDER BY rd.r_name ASC, co.o_totalprice DESC
FETCH FIRST 10 ROWS ONLY;
