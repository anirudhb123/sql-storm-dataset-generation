WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > 0
    UNION ALL
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN SupplyChain sc ON p.p_partkey = sc.p_partkey
    WHERE ps.ps_availqty > sc.ps_availqty
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
),
AggregatedData AS (
    SELECT sc.s_name, SUM(sc.ps_availqty * sc.ps_supplycost) AS total_supply_cost,
           RANK() OVER (PARTITION BY sc.s_name ORDER BY SUM(sc.ps_availqty * sc.ps_supplycost) DESC) AS supplier_rank
    FROM SupplyChain sc
    GROUP BY sc.s_name
)
SELECT co.c_name, co.o_orderkey, co.o_totalprice, ad.total_supply_cost, ad.supplier_rank,
       CASE 
           WHEN ad.total_supply_cost IS NULL THEN 'No Supply'
           ELSE 'Has Supply'
       END AS supply_status
FROM CustomerOrders co
LEFT JOIN AggregatedData ad ON co.o_orderkey = ad.supplier_rank
WHERE co.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
  AND (ad.total_supply_cost IS NULL OR ad.supplier_rank <= 5)
ORDER BY co.o_totalprice DESC, co.c_name;
