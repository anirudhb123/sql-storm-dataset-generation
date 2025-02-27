WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, 
           DENSE_RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderstatus = 'O'
),
MixedDetails AS (
    SELECT p.p_partkey, p.p_name, s.s_name, od.o_totalprice,
           (od.o_totalprice - SUM(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY od.o_orderkey)) AS profit
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN OrderSummary od ON l.l_orderkey = od.o_orderkey
    LEFT JOIN SupplierDetails s ON s.s_nationkey = 
                                    (SELECT n.n_nationkey FROM nation n WHERE n.n_nationkey = 
                                    (SELECT n2.n_nationkey FROM nation n2 WHERE n2.n_name = 'USA'))
)
SELECT r.r_name, COUNT(DISTINCT m.p_partkey) AS part_count, 
       AVG(m.profit) AS average_profit,
       MAX(m.o_totalprice) AS max_order_value
FROM region r
LEFT JOIN MixedDetails m ON r.r_regionkey = 
                            (SELECT n.n_regionkey FROM nation n 
                             JOIN supplier s ON n.n_nationkey = s.s_nationkey 
                             WHERE s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = m.p_partkey))
GROUP BY r.r_name
HAVING AVG(m.profit) IS NOT NULL
ORDER BY average_profit DESC;
