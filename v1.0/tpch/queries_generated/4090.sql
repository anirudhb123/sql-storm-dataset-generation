WITH SupplierTotalCosts AS (
    SELECT ps.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.s_suppkey
),
CriticalOrders AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_custkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, ROW_NUMBER() OVER (ORDER BY st.total_cost DESC) AS rank
    FROM supplier s
    JOIN SupplierTotalCosts st ON s.s_suppkey = st.s_suppkey
    WHERE st.total_cost IS NOT NULL
),
CustomerSales AS (
    SELECT c.c_nationkey, SUM(co.total_revenue) AS total_customer_revenue
    FROM customer c
    LEFT JOIN CriticalOrders co ON c.c_custkey = co.o_custkey
    GROUP BY c.c_nationkey
),
SalesByNation AS (
    SELECT n.n_name, COALESCE(cs.total_customer_revenue, 0) AS customer_revenue
    FROM nation n
    LEFT JOIN CustomerSales cs ON n.n_nationkey = cs.c_nationkey
)
SELECT tn.rank, tn.s_name, CASE 
           WHEN tn.rank <= 5 THEN 'Top 5 Supplier' 
           ELSE 'Other' END AS supplier_category,
           sn.n_name, sn.customer_revenue
FROM TopSuppliers tn
CROSS JOIN SalesByNation sn
WHERE tn.s_suppkey IN (SELECT DISTINCT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_availqty > 0)
ORDER BY tn.rank, sn.n_name;
