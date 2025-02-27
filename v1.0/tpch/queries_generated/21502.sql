WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
), 
HighValueParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, p.p_comment,
           COALESCE(SUM(LineValues.l_extendedprice * (1 - LineValues.l_discount)), 0) AS total_revenue
    FROM part p
    LEFT JOIN (
        SELECT l.l_partkey, l.l_orderkey, l.l_discount, l.l_extendedprice
        FROM lineitem l
        INNER JOIN orders o ON l.l_orderkey = o.o_orderkey
        WHERE o.o_orderstatus = 'F'
    ) AS LineValues ON p.p_partkey = LineValues.l_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice, p.p_comment
    HAVING SUM(LineValues.l_extendedprice * (1 - LineValues.l_discount)) IS NOT NULL 
    OR COUNT(LineValues.l_orderkey) > 0
), 
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           RANK() OVER (ORDER BY COUNT(o.o_orderkey) DESC) AS customer_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT r.r_name, 
       HP.p_name, 
       HP.total_revenue,
       COALESCE(HV.s_name, 'Unknown Supplier') AS supplier_name,
       COALESCE(CO.order_count, 0) AS customer_order_count
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN RankedSuppliers HV ON n.n_nationkey = HV.s_nationkey AND HV.rank = 1
LEFT JOIN HighValueParts HP ON HP.total_revenue > 1000
LEFT JOIN CustomerOrders CO ON CO.order_count > 5
WHERE r.r_name NOT LIKE '%Unknown%'
ORDER BY total_revenue DESC, customer_order_count DESC, supplier_name;
