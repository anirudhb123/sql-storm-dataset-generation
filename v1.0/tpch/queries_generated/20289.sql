WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
HighestSupplier AS (
    SELECT s.s_nationkey, s.s_name, s.s_acctbal
    FROM RankedSuppliers s
    WHERE s.rn = 1
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 
           COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spending
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
    HAVING SUM(o.o_totalprice) > (
        SELECT AVG(o2.o_totalprice) 
        FROM orders o2 
        WHERE o2.o_orderstatus = 'O'
    )
)
SELECT DISTINCT 
    p.p_partkey, p.p_name, 
    COALESCE((SELECT COUNT(DISTINCT l.l_orderkey) 
               FROM lineitem l 
               WHERE l.l_partkey = p.p_partkey 
               AND l.l_returnflag = 'N'), 0) AS non_returned_orders,
    H.s_name AS top_supplier,
    C.order_count,
    C.total_spending,
    CASE 
        WHEN C.total_spending IS NULL THEN 'NO ORDERS'
        WHEN C.total_spending > 10000 THEN 'HIGH SPENDER'
        ELSE 'REGULAR CUSTOMER'
    END AS customer_status
FROM part p
LEFT JOIN HighestSupplier H ON p.p_partkey IN (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    WHERE ps.ps_suppkey = H.s_suppkey
)
LEFT JOIN CustomerOrders C ON C.c_nationkey = (
    SELECT n.n_nationkey 
    FROM nation n 
    WHERE n.n_name = (SELECT r.r_name FROM region r WHERE r.r_regionkey = (
        SELECT DISTINCT n.n_regionkey FROM nation n WHERE n.n_nationkey = H.s_nationkey
    ))
)
WHERE (p.p_size > 100 OR p.p_container LIKE 'BOX%')
AND (p.p_retailprice BETWEEN 50.00 AND 1000.00 OR p.p_comment IS NOT NULL)
ORDER BY non_returned_orders DESC, p.p_partkey
FETCH FIRST 100 ROWS ONLY;
