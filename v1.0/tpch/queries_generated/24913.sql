WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
),
AvgOrderValue AS (
    SELECT o.o_custkey, AVG(o.o_totalprice) AS avg_order_value
    FROM orders o
    GROUP BY o.o_custkey
),
CustomerOrderStatus AS (
    SELECT c.c_custkey, c.c_name, 
           COUNT(CASE WHEN o.o_orderstatus = 'O' THEN 1 END) AS open_orders,
           COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierDetails AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, 
           SUM(ps.ps_availqty) AS total_available_quantity,
           SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
TopParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           ROW_NUMBER() OVER (ORDER BY p.p_retailprice DESC) AS part_rank
    FROM part p
    WHERE p.p_size IS NOT NULL
),
ConsistentSales AS (
    SELECT l.l_partkey, 
           SUM(CASE WHEN l.l_discount > 0.1 THEN l.l_extendedprice END) AS discounted_sales,
           COUNT(DISTINCT l.l_orderkey) AS distinct_orders
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY l.l_partkey
)
SELECT DISTINCT c.c_custkey, c.c_name, 
       ns.n_name AS supplier_nation, 
       AVG(a.avg_order_value) AS average_cust_order_value, 
       p.p_name AS top_part_name,
       COALESCE(ps.total_supply_cost, 0) AS total_supply_cost,
       cs.open_orders, cs.total_orders,
       cs.open_orders - cs.total_orders AS order_difference,
       CASE 
           WHEN cs.open_orders IS NULL THEN 'No Orders'
           ELSE 'Orders Exist'
       END AS order_status
FROM CustomerOrderStatus cs
JOIN AvgOrderValue a ON cs.c_custkey = a.o_custkey
LEFT JOIN RankedSuppliers ns ON cs.open_orders > 0 AND ns.rn <= 3
LEFT JOIN TopParts p ON p.part_rank <= 5
LEFT JOIN PartSupplierDetails ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN nation n ON ns.n_nationkey = n.n_nationkey
WHERE (cs.total_orders IS NULL OR cs.total_orders > 10)
  AND (p.p_retailprice IS NOT NULL OR p.p_retailprice < 100)
ORDER BY average_cust_order_value DESC, c.c_name;
