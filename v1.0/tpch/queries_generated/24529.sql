WITH RECURSIVE SupplierCTE AS (
    SELECT s_suppkey, s_name, s_acctbal, NULL AS parent_sup_key
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT ps.s_suppkey, s.s_name, s.s_acctbal, s.s_suppkey
    FROM SupplierCTE s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_nationkey IS NOT NULL)
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c 
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'F') -- Only count 'Open' and 'Filled' orders
    GROUP BY c.c_custkey, c.c_name
),
PartStats AS (
    SELECT p.p_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_returnflag = 'N' -- Exclude returned items
    GROUP BY p.p_partkey
),
RankedSuppliers AS (
    SELECT s.s_suppkey, RANK() OVER (ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_name, 
           CASE WHEN o.o_totalprice IS NULL THEN 'No Price' 
                ELSE CONCAT('Total: $', CAST(o.o_totalprice AS CHAR)) 
           END AS order_details
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
),
FinalReport AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, 
           COALESCE(ps.total_revenue, 0) AS part_revenue,
           (SELECT SUM(l.l_quantity) 
            FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)) AS total_quantity
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN PartStats ps ON o.o_orderkey = ps.p_partkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT DISTINCT fr.c_name, fr.order_count, fr.part_revenue, 
       COALESCE(NULLIF(fr.total_quantity, 0), 'No Lines') AS total_lines,
       CASE WHEN s.rank IS NULL THEN 'No Supplier' ELSE s.rank END AS supplier_rank
FROM FinalReport fr
LEFT JOIN RankedSuppliers s ON fr.c_custkey = s.s_suppkey
WHERE fr.order_count > 5 AND fr.part_revenue > 1000
ORDER BY fr.order_count DESC, fr.part_revenue DESC;
