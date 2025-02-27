WITH RECURSIVE SupplyChain AS (
    SELECT ps_partkey, ps_suppkey, ps_availqty, ps_supplycost
    FROM partsupp
    WHERE ps_availqty > 0
    UNION ALL
    SELECT p.ps_partkey, s.s_suppkey, p.ps_availqty + ps_availqty AS total_availqty, 
           CASE WHEN p.ps_supplycost < s.s_acctbal THEN p.ps_supplycost ELSE s.s_acctbal END AS effective_cost
    FROM partsupp p
    JOIN supplier s ON p.ps_suppkey = s.s_suppkey
    WHERE p.ps_availqty <= 0
),

CustomerOrders AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),

RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
    WHERE p.p_size >= (SELECT AVG(p_size) FROM part)
),

HighValueSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost) > 10000
)

SELECT 
    c.c_name AS customer_name,
    COALESCE(ho.high_order_count, 0) AS high_order_count,
    COALESCE(sp.total_availqty, 0) AS total_available_parts,
    hp.p_name,
    hp.p_retailprice,
    r.r_name AS region_name
FROM CustomerOrders co
JOIN HighValueSuppliers hvs ON co.c_custkey = hvs.s_suppkey
LEFT JOIN SupplyChain sp ON hvs.s_suppkey = sp.ps_suppkey
JOIN RankedParts hp ON hs_partkey = hp.p_partkey
JOIN nation n ON hvs.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS high_order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey
) ho ON co.c_custkey = ho.c_custkey
WHERE hp.rank <= 5
ORDER BY co.total_spent DESC, hp.p_retailprice ASC;
