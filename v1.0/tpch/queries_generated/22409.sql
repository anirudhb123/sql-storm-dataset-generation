WITH RankedParts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_brand,
           SUM(ps.ps_supplycost * ps.ps_availqty) OVER (PARTITION BY p.p_partkey) AS total_cost,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS brand_rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100)
),
RecentOrders AS (
    SELECT o.o_orderkey, 
           o.o_custkey, 
           o.o_orderdate, 
           o.o_totalprice,
           DENSE_RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS recent_rank
    FROM orders o
    WHERE o.o_orderdate >= DATEADD(month, -6, CURRENT_DATE)
),
HighValueCustomers AS (
    SELECT c.c_custkey, 
           c.c_name
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 5000
),
SupplierDetails AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           COUNT(DISTINCT ps.ps_partkey) AS part_count,
           AVG(ps.ps_supplycost) AS avg_price
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT 
    rp.p_name,
    rp.total_cost,
    ro.o_orderkey,
    ro.o_totalprice,
    CASE 
        WHEN hvc.c_custkey IS NOT NULL THEN 'High Value'
        ELSE 'Regular'
    END AS customer_type,
    sd.part_count,
    sd.avg_price
FROM RankedParts rp
JOIN RecentOrders ro ON rp.brand_rank = 1
LEFT JOIN HighValueCustomers hvc ON ro.o_custkey = hvc.c_custkey
LEFT JOIN SupplierDetails sd ON sd.part_count > 0
WHERE rp.total_cost > (SELECT AVG(total_cost) FROM RankedParts WHERE brand_rank <= 5)
  AND 
    (ro.o_totalprice IS NOT NULL 
     AND ro.o_orderkey IS NOT NULL)
  OR 
    EXISTS (SELECT 1 FROM lineitem l WHERE l.l_orderkey = ro.o_orderkey AND l.l_returnflag = 'N')
ORDER BY rp.total_cost DESC, ro.o_orderkey ASC;
