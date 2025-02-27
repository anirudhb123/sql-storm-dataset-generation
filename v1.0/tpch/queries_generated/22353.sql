WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND o.o_totalprice IS NOT NULL
), BigSpenderStats AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT ro.o_orderkey) AS total_orders,
        SUM(ro.o_totalprice) AS total_spent,
        AVG(ro.o_totalprice) AS avg_spent
    FROM 
        RankedOrders ro
    JOIN 
        nation n ON ro.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.rn <= 5
    GROUP BY 
        r.r_name
), SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
    HAVING 
        COUNT(ps.ps_partkey) > 2
)
SELECT 
    B.r_name,
    B.total_orders,
    B.total_spent,
    B.avg_spent,
    S.total_supply_cost,
    S.avg_account_balance
FROM 
    BigSpenderStats B
LEFT JOIN 
    SupplierSummary S ON B.total_spent > S.total_supply_cost
ORDER BY 
    B.total_spent DESC NULLS LAST
UNION ALL
SELECT 
    'TOTAL' AS r_name,
    SUM(total_orders),
    SUM(total_spent),
    AVG(NULLIF(avg_spent, 0)),
    SUM(total_supply_cost),
    AVG(avg_account_balance)
FROM 
    BigSpenderStats B
CROSS JOIN 
    SupplierSummary S
WHERE 
    B.total_orders IS NOT NULL OR S.total_supply_cost IS NOT NULL
ORDER BY 
    r_name

