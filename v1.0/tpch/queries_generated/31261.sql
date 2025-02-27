WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT sp.s_suppkey, sp.s_name, sp.s_nationkey, sp.s_acctbal, sh.level + 1
    FROM supplier sp
    INNER JOIN SupplierHierarchy sh ON sp.s_nationkey = sh.s_nationkey
    WHERE sp.s_acctbal > sh.s_acctbal
),
RankedLineItems AS (
    SELECT l_orderkey, l_partkey, l_suppkey, l_quantity, l_extendedprice,
           RANK() OVER (PARTITION BY l_orderkey ORDER BY l_extendedprice DESC) AS rnk
    FROM lineitem
    WHERE l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 0
    GROUP BY c.c_custkey, c.c_name
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_availqty
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(ps.ps_availqty) > 100
)
SELECT 
    sh.s_name AS Supplier_Name,
    sh.level AS Hierarchy_Level,
    co.c_name AS Customer_Name,
    co.order_count AS Total_Orders,
    fp.p_name AS Part_Name,
    fp.total_availqty AS Available_Quantity,
    RANK() OVER (PARTITION BY co.c_custkey ORDER BY SUM(li.l_extendedprice) DESC) AS customer_rank
FROM SupplierHierarchy sh
JOIN FilteredParts fp ON sh.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = fp.p_partkey LIMIT 1)
JOIN RankedLineItems li ON li.l_suppkey = sh.s_suppkey
JOIN CustomerOrders co ON co.c_custkey = li.l_orderkey
WHERE sh.s_name IS NOT NULL
AND fp.total_availqty IS NOT NULL
ORDER BY sh.level, co.order_count DESC, customer_rank;
