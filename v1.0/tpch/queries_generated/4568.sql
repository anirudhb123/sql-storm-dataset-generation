WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
CustomerNation AS (
    SELECT 
        c.c_custkey,
        n.n_name AS nation_name,
        c.c_acctbal
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        c.c_acctbal > 1000
),
OrderLineSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(*) AS item_count,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '2023-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    coalesce(r.order_rank, 0) AS order_rank,
    cn.nation_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(ols.total_price) AS total_sales,
    SUM(sp.total_available) AS total_supply_available,
    SUM(o.o_totalprice) AS overall_price
FROM 
    RankedOrders r
FULL OUTER JOIN 
    OrderLineSummary ols ON r.o_orderkey = ols.l_orderkey
LEFT JOIN 
    CustomerNation cn ON r.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cn.c_custkey)
LEFT JOIN 
    SupplierParts sp ON sp.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = r.o_orderkey)
GROUP BY 
    cn.nation_name, r.order_rank
HAVING 
    SUM(sp.total_available) IS NOT NULL
ORDER BY 
    cn.nation_name, order_rank;
