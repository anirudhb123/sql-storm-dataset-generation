WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM orders o
    WHERE o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
    AND o.o_totalprice IS NOT NULL
),
FilteredLineItems AS (
    SELECT 
        li.l_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS NetRevenue,
        COUNT(DISTINCT li.l_partkey) AS UniqueParts
    FROM lineitem li
    WHERE li.l_shipdate >= '2022-01-01' AND li.l_shipdate < '2023-01-01'
    AND li.l_returnflag = 'N'
    GROUP BY li.l_orderkey
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        p.p_name,
        p.p_mfgr,
        s.s_suppkey,
        COUNT(DISTINCT s.s_nationkey) OVER (PARTITION BY s.s_suppkey) AS SupNationCount
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE p.p_size > 10 AND s.s_acctbal IS NOT NULL
),
NationCurrency AS (
    SELECT 
        n.n_name,
        SUM(s.s_acctbal) AS TotalCustBalance,
        SUM(s.s_acctbal) FILTER (WHERE s.s_acctbal > 0) AS PositiveBalance
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    fli.NetRevenue,
    fli.UniqueParts,
    sp.p_name,
    sp.SupNationCount,
    nc.n_name,
    nc.TotalCustBalance,
    nc.PositiveBalance
FROM RankedOrders ro
FULL OUTER JOIN FilteredLineItems fli ON ro.o_orderkey = fli.l_orderkey
LEFT JOIN SupplierParts sp ON fli.UniqueParts > 0 -- bizarre condition to demonstrate NULL logic with UniqueParts
RIGHT JOIN NationCurrency nc ON sp.SupNationCount > 1 -- obscure correlation using a count greater than 1
WHERE ro.OrderRank <= 5 
AND (fli.NetRevenue IS NULL OR fli.UniqueParts > 5)
ORDER BY ro.o_orderdate DESC, fli.NetRevenue DESC NULLS LAST;
