WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
), FilteredOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_lineitem_price
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND o.o_totalprice < 10000
    GROUP BY o.o_orderkey, o.o_orderdate
    HAVING total_lineitem_price > 0
), SupplierPartInfo AS (
    SELECT ps.ps_partkey, p.p_name, s.s_suppkey, s.s_name,
           s.s_acctbal, ps.ps_availqty, ps.ps_supplycost,
           CASE 
               WHEN ps.ps_supplycost > 50 THEN 'High Cost'
               ELSE 'Affordable'
           END AS cost_category
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
), NationalCustomerData AS (
    SELECT c.c_custkey, c.c_name, n.n_name,
           SUM(o.o_totalprice) AS total_order_price,
           RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS cust_rank
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, n.n_name
)
SELECT r.s_name, c.c_name, o.o_orderkey, o.o_orderdate,
       COALESCE(sp.cost_category, 'Unknown') AS part_cost_category,
       s.rank AS supplier_rank, n.total_order_price
FROM RankedSuppliers r
FULL OUTER JOIN FilteredOrders o ON o.o_orderkey % 5 = r.s_suppkey % 5
LEFT JOIN SupplierPartInfo sp ON sp.s_suppkey = r.s_suppkey
JOIN NationalCustomerData n ON n.total_order_price < r.s_acctbal
WHERE n.cust_rank <= 3
AND (r.rank IS NULL OR r.rank <= 10)
ORDER BY r.s_name DESC, n.n_name, o.o_orderdate;
