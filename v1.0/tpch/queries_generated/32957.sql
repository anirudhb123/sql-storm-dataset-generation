WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS depth
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.depth + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
PartSupplierDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, ps.ps_supplycost, ps.ps_availqty, r.r_name AS region_name
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE p.p_retailprice > 100
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_line_item_price
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    ch.order_count,
    ch.total_spent,
    od.total_line_item_price,
    CASE 
        WHEN ch.total_spent IS NULL THEN 'No Orders'
        ELSE 'Orders Present'
    END AS order_status
FROM 
    PartSupplierDetails ps
LEFT JOIN 
    CustomerOrders ch ON ps.p_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_supplycost < 50)
LEFT JOIN 
    OrderDetails od ON od.o_orderdate > '2023-01-01' AND od.o_orderkey IN (SELECT o_orderkey FROM orders WHERE o_orderstatus = 'F')
GROUP BY 
    p.p_partkey, p.p_name, ch.order_count, ch.total_spent, od.total_line_item_price
HAVING 
    SUM(ps.ps_availqty) > 1000
ORDER BY 
    p.p_name, supplier_count DESC;
