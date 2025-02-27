WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM orders o
),
SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost) AS TotalSupplyCost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
FilteredCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS CustRank
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_mktsegment = c.c_mktsegment)
),
ComplexJoin AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(SUM(l.l_quantity), 0) AS TotalQuantity,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS AvgExtendedPrice
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE p.p_retailprice > 20.00
    GROUP BY p.p_partkey, p.p_name
),
FinalReport AS (
    SELECT 
        r.r_name,
        n.n_name,
        SUM(s.TotalSupplyCost) AS TotalCost,
        SUM(CASE WHEN co.OrderRank IS NOT NULL THEN co.o_totalprice ELSE 0 END) AS TotalOrderValue,
        COUNT(DISTINCT fc.c_custkey) AS DistinctCustomerCount,
        STRING_AGG(DISTINCT CONCAT('Part: ', cp.p_name, ' | Avg Price: ', COALESCE(cp.AvgExtendedPrice, 0)) ORDER BY cp.AvgExtendedPrice DESC) AS DetailedParts
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN SupplierCost sc ON s.s_suppkey = sc.ps_suppkey
    LEFT JOIN RankedOrders co ON co.o_orderkey = (SELECT l.l_orderkey FROM lineitem l WHERE l.l_suppkey = s.s_suppkey ORDER BY l.l_extendedprice DESC LIMIT 1)
    LEFT JOIN ComplexJoin cp ON cp.p_partkey = sc.ps_partkey
    LEFT JOIN FilteredCustomers fc ON fc.c_custkey = (SELECT od.o_custkey FROM orders od WHERE od.o_orderkey = co.o_orderkey LIMIT 1)
    GROUP BY r.r_name, n.n_name
)
SELECT * 
FROM FinalReport
WHERE TotalCost IS NOT NULL 
AND DistinctCustomerCount > 1
ORDER BY TotalCost DESC, DistinctCustomerCount DESC;
