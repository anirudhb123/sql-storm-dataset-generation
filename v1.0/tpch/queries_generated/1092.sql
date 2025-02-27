WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_customerkey,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01'
), 
SupplierPrices AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_supplycost,
        p.p_retailprice,
        (p.p_retailprice - ps.ps_supplycost) AS PriceDifference
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
), 
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (ORDER BY SUM(sp.PriceDifference) DESC) AS SupplierRank
    FROM SupplierPrices sp
    JOIN supplier s ON sp.ps_suppkey = s.s_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    c.c_name,
    t.s_name AS TopSupplierName,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice ELSE 0 END) AS ReturnedAmount,
    SUM(CASE WHEN l.l_returnflag <> 'R' THEN l.l_extendedprice ELSE 0 END) AS NonReturnedAmount
FROM RankedOrders o
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN customer c ON o.o_custkey = c.c_custkey
LEFT JOIN TopSuppliers t ON l.l_suppkey = t.s_suppkey
WHERE t.SupplierRank <= 5 OR t.SupplierRank IS NULL
GROUP BY o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, t.s_name
HAVING SUM(l.l_quantity) > 100
ORDER BY o.o_orderdate DESC, o.o_totalprice DESC;
