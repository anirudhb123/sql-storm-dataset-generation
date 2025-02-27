WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_acctbal
    FROM supplier s
), FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           CASE 
               WHEN p.p_size BETWEEN 1 AND 10 THEN 'Small'
               WHEN p.p_size BETWEEN 11 AND 20 THEN 'Medium'
               WHEN p.p_size > 20 THEN 'Large'
               ELSE 'Undefined'
           END AS size_category
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
), OrderLineQuantities AS (
    SELECT o.o_orderkey, SUM(l.l_quantity) AS total_quantity
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
), SupplierPartDetails AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, 
           ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS lowest_cost_supplier
    FROM partsupp ps
), NationwideCustomerStats AS (
    SELECT n.n_name, COUNT(DISTINCT c.c_custkey) AS customer_count,
           AVG(c.c_acctbal) AS avg_account_balance
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey
)
SELECT DISTINCT 
    r.r_name, 
    p.p_name AS part_name, 
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    COALESCE(s_acctbal + 0, 0) AS supplier_account_balance, 
    o.orderdate,
    CASE 
        WHEN ol.total_quantity > 100 THEN 'High Volume'
        WHEN ol.total_quantity BETWEEN 50 AND 100 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS volume_category,
    ns.customer_count,
    ns.avg_account_balance
FROM RankedSuppliers s
FULL OUTER JOIN SupplierPartDetails spd ON s.s_suppkey = spd.ps_suppkey AND spd.lowest_cost_supplier = 1
JOIN FilteredParts p ON p.p_partkey = spd.ps_partkey
LEFT JOIN orders o ON o.o_custkey = s.s_suppkey
LEFT JOIN OrderLineQuantities ol ON o.o_orderkey = ol.o_orderkey
JOIN NationwideCustomerStats ns ON s.s_nationkey = ns.n_nationkey
WHERE (s.s_acctbal IS NULL OR s.s_acctbal > 100.00) 
      AND (p.p_name LIKE '%widget%' OR p.p_name IS NULL)
ORDER BY r.r_name, part_name;
