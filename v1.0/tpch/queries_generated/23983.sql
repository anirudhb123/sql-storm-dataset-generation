WITH RankedParts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_mfgr, 
           p.p_retailprice, 
           ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS PriceRank
    FROM part p
),
AvailableSuppliers AS (
    SELECT ps.ps_partkey, 
           SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_availqty) > 0
),
CustomerOrders AS (
    SELECT o.o_orderkey, 
           o.o_custkey, 
           o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
)
SELECT DISTINCT 
    n.n_name, 
    r.r_name, 
    cp.total_order_value,
    pp.p_name, 
    pp.p_retailprice, 
    pp.PriceRank,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    CASE 
        WHEN cp.total_order_value IS NULL THEN 'Order not found'
        ELSE 'Order found'
    END AS order_status_info
FROM RankedParts pp
LEFT JOIN AvailableSuppliers ps ON pp.p_partkey = ps.ps_partkey
RIGHT JOIN CustomerOrders cp ON cp.total_order_value > pp.p_retailprice
JOIN nation n ON n.n_nationkey = (SELECT c.c_nationkey 
                                    FROM customer c 
                                    WHERE c.c_custkey = cp.o_custkey)
JOIN region r ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey AND s.s_acctbal > 
    (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = n.n_nationkey)
WHERE pp.PriceRank <= 10 
  AND (pp.p_retailprice IS NOT NULL OR ps.total_available IS NOT NULL)
  AND (cp.o_orderdate BETWEEN DATEADD(MONTH, -6, GETDATE()) AND GETDATE() 
       OR pp.p_comment LIKE '%urgent%')
ORDER BY n.n_name, pp.p_retailprice DESC;
