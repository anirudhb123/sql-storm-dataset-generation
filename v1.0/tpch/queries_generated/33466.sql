WITH RECURSIVE CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, co.level + 1
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN CustomerOrders co ON o.o_orderkey > co.o_orderkey
    WHERE o.o_orderstatus = 'O'
),
SupplierPartCost AS (
    SELECT ps.ps_partkey, s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_suppkey
),
PartSupplierDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, sp.total_cost,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY sp.total_cost DESC) AS rn
    FROM part p
    LEFT JOIN SupplierPartCost sp ON p.p_partkey = sp.ps_partkey
),
NationRegionSales AS (
    SELECT n.n_nationkey, r.r_regionkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_shipdate >= '2022-01-01'
    GROUP BY n.n_nationkey, r.r_regionkey
)
SELECT co.c_custkey, co.c_name, SUM(co.o_totalprice) AS total_order_value, 
       COUNT(DISTINCT co.o_orderkey) AS order_count, 
       CASE WHEN SUM(p.p_retailprice) IS NULL THEN 'No Purchases' ELSE 'Has Purchases' END AS purchase_status,
       COUNT(DISTINCT ns.n_nationkey) AS unique_nations
FROM CustomerOrders co
LEFT JOIN PartSupplierDetails p ON co.o_orderkey = p.p_partkey
LEFT JOIN NationRegionSales ns ON co.o_custkey = ns.n_nationkey
GROUP BY co.c_custkey, co.c_name
HAVING COUNT(DISTINCT co.o_orderkey) > 2
ORDER BY total_order_value DESC, order_count DESC;
