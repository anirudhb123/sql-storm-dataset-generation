WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        total_supply_value > 1000000
),
RecentLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '2023-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.c_name,
    ro.c_acctbal,
    hl.total_supply_value,
    rl.total_lineitem_value,
    CASE 
        WHEN ro.order_rank <= 10 THEN 'Top Order'
        ELSE 'Standard Order'
    END AS order_category
FROM 
    RankedOrders ro
LEFT JOIN 
    HighValueSuppliers hl ON EXISTS (
        SELECT 1 
        FROM lineitem l 
        WHERE l.l_orderkey = ro.o_orderkey 
        AND l.l_suppkey IN (SELECT s.s_suppkey FROM HighValueSuppliers s)
    )
LEFT JOIN 
    RecentLineItems rl ON ro.o_orderkey = rl.l_orderkey
WHERE 
    ro.o_totalprice > 500
ORDER BY 
    ro.o_orderdate DESC, ro.o_totalprice DESC;
