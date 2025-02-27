WITH RECURSIVE CustomerOrderCTE AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, 
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 1000.00
),
PartSupplierCTE AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, 
           SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size > 10
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
ExcessiveOrderInfo AS (
    SELECT co.c_custkey, co.o_orderkey, co.o_orderdate, 
           COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_price,
           ROW_NUMBER() OVER (PARTITION BY co.c_custkey ORDER BY COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) DESC) AS price_rank
    FROM CustomerOrderCTE co
    LEFT JOIN lineitem l ON co.o_orderkey = l.l_orderkey
    GROUP BY co.c_custkey, co.o_orderkey, co.o_orderdate
),
NationSupplier AS (
    SELECT n.n_name, s.s_name, s.s_acctbal 
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 500.00
),
FinalOutput AS (
    SELECT DISTINCT 
        e.c_custkey,
        e.o_orderkey,
        e.total_price,
        ns.n_name,
        ns.s_name,
        ns.s_acctbal
    FROM ExcessiveOrderInfo e
    LEFT JOIN NationSupplier ns ON e.c_custkey = ns.s_suppkey
    WHERE e.total_price = (SELECT MAX(total_price) FROM ExcessiveOrderInfo WHERE c_custkey = e.c_custkey)
)

SELECT f.c_custkey, f.o_orderkey, f.total_price,
       CASE 
           WHEN f.total_price IS NULL THEN 'No Price'
           ELSE CAST(f.total_price AS varchar(20))
       END AS price_str,
       n.r_name AS region_name,
       COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
FROM FinalOutput f
LEFT JOIN region r ON f.n_name IS NULL AND r.r_regionkey = 0
LEFT JOIN part p ON f.c_custkey = p.p_partkey
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
GROUP BY f.c_custkey, f.o_orderkey, f.total_price, n.r_name;
