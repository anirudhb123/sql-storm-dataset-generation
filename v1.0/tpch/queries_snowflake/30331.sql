
WITH RECURSIVE RegionNations AS (
    SELECT r.r_regionkey, r.r_name, n.n_nationkey, n.n_name
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    UNION ALL
    SELECT rn.r_regionkey, rn.r_name, n.n_nationkey, n.n_name
    FROM RegionNations rn
    JOIN nation n ON rn.r_regionkey = n.n_regionkey
    WHERE rn.n_nationkey <> n.n_nationkey
),
SupplierMetrics AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, COUNT(ps.ps_partkey) AS total_parts,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrderDetails AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice,
           DENSE_RANK() OVER (PARTITION BY c.c_custkey ORDER BY o.o_totalprice DESC) AS rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
)
SELECT r.n_name AS Nation, sm.s_name AS Supplier, cm.c_name AS Customer,
       COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS Total_Revenue,
       COUNT(DISTINCT o.o_orderkey) AS Total_Orders,
       MAX(CASE WHEN l.l_shipdate > o.o_orderdate THEN l.l_shipdate END) AS Latest_Ship_Date,
       AVG(sm.total_supply_cost) AS Avg_Supply_Cost_Per_Supplier,
       MAX(cm.o_totalprice) AS Max_Order_Price
FROM RegionNations r
FULL OUTER JOIN SupplierMetrics sm ON r.n_nationkey = sm.s_suppkey
LEFT JOIN CustomerOrderDetails cm ON sm.s_suppkey = cm.c_custkey
LEFT JOIN lineitem l ON l.l_orderkey = cm.o_orderkey
LEFT JOIN orders o ON o.o_orderkey = l.l_orderkey
WHERE COALESCE(sm.s_acctbal, 0) > 10000 
AND r.r_regionkey IS NOT NULL 
AND (l.l_returnflag = 'N' OR l.l_returnflag IS NULL)
GROUP BY r.n_name, sm.s_name, cm.c_name
ORDER BY Total_Revenue DESC, Nation ASC, Customer ASC;
