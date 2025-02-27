WITH RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, 
           p.p_retailprice, p.p_comment,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) as price_rank
    FROM part p
    WHERE p.p_size IN (10, 20, 30)
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderpriority, 
           c.c_name, c.c_acctbal, c.c_mktsegment,
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) as order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01' 
      AND o.o_totalprice > 1000
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, COUNT(ps.ps_partkey) as part_count, 
           SUM(ps.ps_supplycost * ps.ps_availqty) as total_supply_cost,
           RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) as supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT r.r_name, hp.p_name, hvo.o_orderkey, hvo.o_orderdate, 
       hvo.o_totalprice, s.s_name, s.total_supply_cost
FROM RankedParts hp
JOIN HighValueOrders hvo ON hp.p_partkey IN (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    WHERE ps.ps_suppkey IN (
        SELECT s.s_suppkey 
        FROM SupplierStats s 
        WHERE s.supplier_rank <= 5
    )
)
JOIN nation n ON n.n_nationkey = (
    SELECT c.c_nationkey 
    FROM customer c 
    WHERE c.c_custkey IN (SELECT hvo.o_custkey FROM HighValueOrders hvo)
    LIMIT 1
)
JOIN region r ON n.n_regionkey = r.r_regionkey
ORDER BY r.r_name, hp.p_name, hvo.o_totalprice DESC;
