WITH RankedSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
), 
HighValueParts AS (
    SELECT p.p_partkey,
           p.p_name,
           p.p_retailprice,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 1000
), 
CustomerRecentOrders AS (
    SELECT c.c_custkey,
           c.c_name,
           COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent,
           MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING MAX(o.o_orderdate) >= CURRENT_DATE - INTERVAL '90 days'
), 
SupplierStats AS (
    SELECT ns.n_nationkey,
           COUNT(DISTINCT s.s_suppkey) AS num_suppliers,
           AVG(s.s_acctbal) AS avg_acctbal,
           MAX(s.s_acctbal) AS max_acctbal
    FROM nation ns
    LEFT JOIN supplier s ON ns.n_nationkey = s.s_nationkey
    GROUP BY ns.n_nationkey
),
PartSales AS (
    SELECT l.l_partkey,
           COUNT(l.l_orderkey) AS order_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           SUM(l.l_tax) AS total_tax,
           AVG(l.l_quantity) AS avg_quantity
    FROM lineitem l
    GROUP BY l.l_partkey
)
SELECT s_name,
       p_name,
       order_count,
       total_spent,
       (SELECT AVG(total_spent) FROM CustomerRecentOrders) AS avg_recent_spent,
       total_sales,
       CASE 
           WHEN avg_acctbal IS NULL THEN 'No Suppliers'
           ELSE CAST(avg_acctbal AS CHAR(25))
       END AS avg_supplier_bal,
       rnk
FROM HighValueParts p
JOIN PartSales ps ON p.p_partkey = ps.l_partkey
JOIN CustomerRecentOrders c ON c.order_count > 10
JOIN RankedSuppliers rs ON rs.rnk = 1 AND rs.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE ps.ps_availqty > 0
)
LEFT JOIN SupplierStats ss ON true
WHERE p.p_retailprice < 500
ORDER BY total_spent DESC, total_sales ASC, c_name;
