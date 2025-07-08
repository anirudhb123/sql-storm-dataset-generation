WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('F', 'O') AND 
        (o.o_totalprice < 50000 OR o.o_totalprice IS NULL)
), 
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(NULLIF(s.s_comment, ''), 'No Comment') AS SafeComment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2) AND 
        s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE '%land%')
),
LineItemCounts AS (
    SELECT 
        l.l_orderkey,
        COUNT(*) AS ItemCount
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    si.s_name,
    si.SafeComment,
    COALESCE(lc.ItemCount, 0) AS TotalItems,
    RANK() OVER (ORDER BY o.o_totalprice) AS PriceRank
FROM 
    RankedOrders o
LEFT JOIN 
    LineItemCounts lc ON o.o_orderkey = lc.l_orderkey
JOIN 
    SupplierInfo si ON si.s_suppkey = (SELECT ps.ps_suppkey 
                                        FROM partsupp ps 
                                        WHERE ps.ps_partkey IN 
                                        (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey)
                                        LIMIT 1)
WHERE 
    (o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2) OR o.o_totalprice IS NULL)
    AND o.OrderRank <= 10
ORDER BY 
    o.o_orderdate DESC NULLS LAST;
