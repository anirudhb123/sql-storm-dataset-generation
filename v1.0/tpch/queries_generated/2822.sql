WITH RankedOrders AS (
    SELECT 
        o_orderkey,
        o_custkey,
        o_orderstatus,
        o_totalprice,
        o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_orderdate DESC) AS rn
    FROM 
        orders
    WHERE 
        o_orderstatus = 'O'
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        n.n_name AS nation
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        c.c_acctbal > (SELECT AVG(c_inner.c_acctbal) FROM customer c_inner)
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderLineSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(l.l_linenumber) AS item_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    cd.c_name,
    cd.nation,
    COUNT(DISTINCT ro.o_orderkey) AS order_count,
    SUM(ols.net_revenue) AS total_revenue,
    COALESCE(ss.total_supply_cost, 0) AS supplier_cost
FROM 
    CustomerDetails cd
LEFT JOIN 
    RankedOrders ro ON cd.c_custkey = ro.o_custkey
LEFT JOIN 
    OrderLineSummary ols ON ols.l_orderkey = ro.o_orderkey
LEFT JOIN 
    SupplierStats ss ON ss.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
        WHERE l.l_orderkey = ro.o_orderkey 
        LIMIT 1
    )
WHERE 
    cd.nation IS NOT NULL
GROUP BY 
    cd.c_name, cd.nation
HAVING 
    COUNT(DISTINCT ro.o_orderkey) > 0
ORDER BY 
    total_revenue DESC, cd.nation;
