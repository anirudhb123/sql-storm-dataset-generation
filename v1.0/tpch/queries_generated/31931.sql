WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS Level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s2.s_suppkey, s2.s_name, s2.s_nationkey, sh.Level + 1
    FROM supplier s2
    JOIN SupplierHierarchy sh ON s2.s_nationkey = sh.s_nationkey
    WHERE sh.Level < 3
),
NationDetails AS (
    SELECT n.n_nationkey, n.n_name, r.r_name, COUNT(s.s_suppkey) AS SupplierCount
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name, r.r_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
RankedLineItems AS (
    SELECT l.*, RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS Rank
    FROM lineitem l
)
SELECT 
    nd.n_name, nd.r_name,
    COUNT(DISTINCT sh.s_suppkey) AS ActiveSuppliers,
    COALESCE(SUM(co.TotalSpent), 0) AS TotalCustomerSpent,
    COUNT(DISTINCT fp.p_partkey) AS HighValueParts,
    COUNT(DISTINCT rl.l_orderkey) AS TotalOrders,
    MAX(rl.l_shipdate) AS LatestShipDate
FROM 
    NationDetails nd
LEFT JOIN 
    SupplierHierarchy sh ON nd.n_nationkey = sh.s_nationkey
LEFT JOIN 
    CustomerOrders co ON co.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = nd.n_nationkey)
LEFT JOIN 
    FilteredParts fp ON fp.p_partkey IN (SELECT DISTINCT ps.ps_partkey FROM partsupp ps JOIN supplier s ON ps.ps_suppkey = s.s_suppkey WHERE s.s_nationkey = nd.n_nationkey)
LEFT JOIN 
    RankedLineItems rl ON rl.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = nd.n_nationkey))
GROUP BY 
    nd.n_name, nd.r_name
HAVING 
    COUNT(DISTINCT sh.s_suppkey) > 0
ORDER BY 
    nd.r_name, nd.n_name;
