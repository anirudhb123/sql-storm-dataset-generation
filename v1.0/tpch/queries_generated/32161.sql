WITH RECURSIVE PricePerSupplier AS (
    SELECT ps.ps_suppkey,
           SUM(ps.ps_supplycost * p.p_retailprice) AS total_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_suppkey
),
CustomerOrders AS (
    SELECT c.c_custkey,
           c.c_name,
           COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierRegion AS (
    SELECT s.s_suppkey,
           n.n_name AS nation,
           r.r_name AS region,
           ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(ps.ps_supplycost) DESC) AS rn,
           SUM(ps.ps_supplycost) AS total_supplycost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, n.n_name, r.r_name
)
SELECT cs.c_name,
       cs.order_count,
       cs.total_spent,
       ps.suppkey,
       CASE 
           WHEN ps.total_cost IS NULL THEN 'No Suppliers'
           ELSE ps.total_cost
       END AS supplier_cost,
       sr.nation,
       sr.region
FROM CustomerOrders cs
LEFT JOIN PricePerSupplier ps ON ps.ps_suppkey = (
    SELECT ps_suppkey 
    FROM partsupp 
    WHERE ps_partkey IN (SELECT p_partkey 
                          FROM part 
                          WHERE p_size >= 10 AND p_size < 20) 
    ORDER BY ps_supplycost DESC 
    LIMIT 1
)
LEFT JOIN SupplierRegion sr ON sr.s_suppkey = ps.ps_suppkey AND sr.rn = 1
WHERE cs.total_spent > 100 OR cs.order_count > 5
ORDER BY cs.total_spent DESC, cs.order_count ASC;
