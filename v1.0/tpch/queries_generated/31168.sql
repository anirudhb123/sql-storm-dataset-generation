WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, NULL::integer AS parent_suppkey
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.s_suppkey
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.parent_suppkey
),
CustomerComparison AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           AVG(o.o_totalprice) AS avg_order_value,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
RankedCustomers AS (
    SELECT c.*, RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM CustomerComparison c
),
AvailableParts AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    r.n_name AS region,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(CASE WHEN lt.l_returnflag = 'R' THEN lt.l_quantity ELSE 0 END) AS total_returned_qty,
    AVG(CASE WHEN lt.l_discount > 0 THEN lt.l_extendedprice * (1 - lt.l_discount) ELSE NULL END) AS avg_discounted_price,
    p.p_name AS part_name,
    p.total_available,
    CASE 
        WHEN rc.rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_category
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN lineitem lt ON p.p_partkey = lt.l_partkey
LEFT JOIN RankedCustomers rc ON s.s_suppkey = rc.c_custkey
GROUP BY r.n_name, p.p_name, p.total_available, rc.rank
HAVING COUNT(DISTINCT c.c_custkey) > 10 AND SUM(ps.ps_availqty) > 100
ORDER BY total_customers DESC, total_returned_qty ASC;
