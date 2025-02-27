WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
PartStatistics AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_avail_qty,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CityCustomerCounts AS (
    SELECT c.c_address, COUNT(DISTINCT c.c_custkey) AS cust_count
    FROM customer c
    GROUP BY c.c_address
),
MaxLineItem AS (
    SELECT l.l_orderkey, MAX(l.l_extendedprice) AS max_price
    FROM lineitem l
    GROUP BY l.l_orderkey
),
CombinedData AS (
    SELECT ph.p_partkey, ph.p_name, ps.total_avail_qty,
           ps.supplier_count, cc.cust_count, 
           ml.max_price, r.r_name
    FROM PartStatistics ps
    JOIN SupplierHierarchy sh ON ps.total_avail_qty > 100
    LEFT JOIN CityCustomerCounts cc ON cc.cust_count > 0
    JOIN MaxLineItem ml ON ml.l_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_totalprice = ml.max_price LIMIT 1)
    JOIN region r ON r.r_regionkey = sh.s_nationkey
)
SELECT cd.p_partkey, cd.p_name, cd.total_avail_qty, cd.supplier_count,
       COALESCE(cd.cust_count, 0) as cust_count, cd.max_price, 
       CASE 
           WHEN cd.supplier_count > 5 THEN 'High'
           WHEN cd.supplier_count BETWEEN 3 AND 5 THEN 'Medium'
           ELSE 'Low'
       END AS supplier_rating
FROM CombinedData cd
WHERE cd.total_avail_qty IS NOT NULL
ORDER BY cd.supplier_rating DESC, cd.total_avail_qty DESC
LIMIT 100;
