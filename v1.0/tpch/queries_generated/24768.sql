WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_acctbal
    FROM supplier s
), TotalOrders AS (
    SELECT o.o_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_revenue
    FROM orders o
    GROUP BY o.o_custkey
), FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, ps.ps_supplycost, ps.ps_availqty,
           CASE 
               WHEN ps.ps_availqty IS NULL THEN 'Unavailable'
               ELSE 
                   CASE 
                       WHEN ps.ps_availqty < 100 THEN 'Limited Stock'
                       ELSE 'In Stock'
                   END
           END AS availability
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size BETWEEN 1 AND 100
), CustomerRevenue AS (
    SELECT c.c_custkey, c.c_name, COALESCE(to.total_revenue, 0) AS total_revenue,
           CASE WHEN coalesce(to.total_revenue, 0) > 5000 THEN 'High Value'
                ELSE 'Low Value'
           END as customer_segment
    FROM customer c
    LEFT JOIN TotalOrders to ON c.c_custkey = to.o_custkey
), RelevantLineItems AS (
    SELECT l.l_partkey, l.l_orderkey, l.l_quantity, l.l_extendedprice, l.l_discount,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS item_rank
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
)

SELECT cs.c_custkey, cs.c_name, ps.p_name, ps.availability, l.l_orderkey,
       SUM(CASE WHEN r.rank_acctbal = 1 THEN r.s_acctbal ELSE 0 END) AS best_supplier_acctbal,
       GRADIENT(cs.total_revenue) OVER (ORDER BY cs.c_custkey) AS revenue_gradient,
       CASE
           WHEN l.l_quantity * (1 - l.l_discount) > 100 THEN 'Large Order'
           ELSE 'Regular Order'
       END AS order_type,
       COALESCE(NULLIF(MAX(ps.p_retailprice), 0), NULL) AS max_retail_price
FROM CustomerRevenue cs
JOIN RelevantLineItems l ON cs.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = l.l_orderkey)
JOIN FilteredParts ps ON l.l_partkey = ps.p_partkey
JOIN RankedSuppliers r ON l.l_suppkey = r.s_suppkey AND r.rank_acctbal <= 3
WHERE cs.customer_segment = 'High Value'
GROUP BY cs.c_custkey, cs.c_name, ps.p_name, ps.availability, l.l_orderkey
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY cs.c_custkey ASC, ps.p_name DESC;
