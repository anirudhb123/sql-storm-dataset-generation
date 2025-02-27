WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
PartSupplies AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty
    FROM partsupp ps
    JOIN SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
    GROUP BY ps.ps_partkey
),
NationPartCounts AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT p.p_partkey) AS num_parts
    FROM nation n
    LEFT JOIN part p ON n.n_nationkey = (SELECT s.s_nationkey FROM supplier s JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey WHERE ps.ps_partkey = p.p_partkey LIMIT 1)
    GROUP BY n.n_nationkey, n.n_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
OrderLineItems AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price_calculated
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N' 
    GROUP BY o.o_orderkey
),
FinalReport AS (
    SELECT 
        n.n_name AS Nation, 
        COUNT(DISTINCT o.o_orderkey) AS TotalOrders, 
        SUM(ol.total_price_calculated) AS GrossRevenue, 
        AVG(c.total_spent) AS AverageCustomerSpend
    FROM nation n
    JOIN CustomerOrders c ON n.n_nationkey = c.c_custkey /* Assuming customer key maps to nation key for fun */
    LEFT JOIN OrderLineItems ol ON c.c_custkey = ol.o_orderkey
    LEFT JOIN PartSupplies ps ON ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 10)
    GROUP BY n.n_name
)
SELECT 
    fr.Nation,
    fr.TotalOrders,
    fr.GrossRevenue,
    fr.AverageCustomerSpend,
    COALESCE(sh.s_name, 'Not Available') AS HighestSpendingSupplier
FROM FinalReport fr
LEFT JOIN Supplier s ON fr.Nation = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = s.s_nationkey)
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = (SELECT s.s_suppkey FROM supplier s ORDER BY s.s_acctbal DESC LIMIT 1)
ORDER BY fr.GrossRevenue DESC;
