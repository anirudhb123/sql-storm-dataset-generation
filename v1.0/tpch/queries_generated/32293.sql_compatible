
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, NULL AS parent_suppkey
    FROM supplier s
    WHERE s.s_name LIKE 'Supplier%'
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.s_suppkey
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
    WHERE s.s_name LIKE 'Supplier%'
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    ORDER BY total_spent DESC
    LIMIT 10
),
PartSupplier AS (
    SELECT p.p_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
RegionSales AS (
    SELECT n.n_regionkey, SUM(os.total_sales) AS region_sales
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN OrderSummary os ON s.s_suppkey = os.o_orderkey
    GROUP BY n.n_regionkey
)

SELECT r.r_name, COALESCE(rs.region_sales, 0) AS region_totals,
       COALESCE(ts.total_spent, 0) AS top_customer_spending,
       ps.total_supply_cost
FROM region r
LEFT JOIN RegionSales rs ON r.r_regionkey = rs.n_regionkey
LEFT JOIN TopCustomers ts ON ts.c_custkey = (
    SELECT MIN(c.c_custkey) 
    FROM TopCustomers c 
    WHERE ts.total_spent = c.total_spent 
    LIMIT 1)
LEFT JOIN PartSupplier ps ON ps.p_partkey = (
    SELECT p.p_partkey
    FROM part p
    ORDER BY p.p_retailprice DESC
    LIMIT 1)
ORDER BY r.r_name;
