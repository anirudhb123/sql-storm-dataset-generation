WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(MONTH, -12, GETDATE()) 
        AND o.o_orderstatus IN ('O', 'F')
), RecentLineItems AS (
    SELECT 
        li.l_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        COUNT(li.l_linenumber) AS item_count
    FROM 
        lineitem li
    WHERE 
        li.l_shipdate BETWEEN DATEADD(DAY, -30, GETDATE()) AND GETDATE()
    GROUP BY 
        li.l_orderkey
), SupplierPartInfo AS (
    SELECT 
        ps.ps_partkey,
        p.p_brand,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, p.p_brand
), NationalSupplier AS (
    SELECT 
        s.s_suppkey,
        n.n_name,
        SUM(s.s_acctbal) AS total_balance
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, n.n_name
)
SELECT
    r.o_orderkey,
    r.o_orderstatus,
    r.o_totalprice,
    r.o_orderdate,
    r.o_orderpriority,
    r1.total_revenue,
    COALESCE(spi.total_supply_cost, 0) AS supply_cost,
    ns.total_balance
FROM
    RankedOrders r
LEFT JOIN 
    RecentLineItems r1 ON r.o_orderkey = r1.l_orderkey
LEFT JOIN 
    SupplierPartInfo spi ON r.o_orderkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_partkey = r.o_orderkey LIMIT 1)
LEFT JOIN 
    NationalSupplier ns ON ns.s_suppkey = (SELECT TOP 1 s.s_suppkey FROM supplier s WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'A%') ORDER BY s.s_acctbal DESC)
WHERE 
    r.rn = 1 
    AND (r.o_orderstatus IS NULL OR r.o_orderstatus <> 'N')
ORDER BY 
    r.o_orderdate DESC, r.o_totalprice DESC;
