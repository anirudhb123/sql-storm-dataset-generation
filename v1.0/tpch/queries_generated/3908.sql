WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) as order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' 
        AND o.o_orderdate < DATE '2024-01-01'
),
SupplierSummary AS (
    SELECT 
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
),
OrderDetails AS (
    SELECT 
        lo.l_orderkey, 
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS revenue,
        COUNT(DISTINCT lo.l_partkey) AS line_count
    FROM 
        lineitem lo
    GROUP BY 
        lo.l_orderkey
),
CustomerNation AS (
    SELECT 
        c.c_nationkey,
        SUM(c.c_acctbal) AS total_acctbal
    FROM 
        customer c
    GROUP BY 
        c.c_nationkey
)
SELECT 
    r.r_name,
    COALESCE(SUM(ss.total_supplycost), 0) AS total_supply_cost,
    COALESCE(COUNT(DISTINCT o.o_orderkey), 0) AS total_orders,
    COALESCE(SUM(od.revenue), 0) AS total_revenue,
    COALESCE(SUM(cn.total_acctbal), 0) AS total_account_balance
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplierSummary ss ON n.n_nationkey = ss.s_nationkey
LEFT JOIN 
    orders o ON o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
LEFT JOIN 
    OrderDetails od ON o.o_orderkey = od.l_orderkey
LEFT JOIN 
    CustomerNation cn ON n.n_nationkey = cn.c_nationkey
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_name
ORDER BY 
    r.r_name;
