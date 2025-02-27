WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_clerk,
        ROW_NUMBER() OVER (PARTITION BY o.o_clerk ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (
            SELECT AVG(o_totalprice) 
            FROM orders 
        )
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSupplyInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        MAX(l.l_shipdate) AS last_ship_date
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    c.c_name,
    cos.total_orders,
    cos.total_spent,
    pi.p_name,
    pi.total_avail_qty,
    pi.avg_supply_cost,
    lis.total_revenue,
    lis.last_ship_date
FROM 
    CustomerOrderStats cos
JOIN 
    RankedOrders ro ON cos.total_orders > 0
LEFT JOIN 
    LineItemStats lis ON ro.o_orderkey = lis.l_orderkey
JOIN 
    PartSupplyInfo pi ON pi.total_avail_qty > 0
WHERE 
    EXISTS (
        SELECT 1 
        FROM supplier s 
        WHERE s.s_nationkey = c.c_nationkey
        AND s.s_acctbal IS NOT NULL
    )
ORDER BY 
    cos.total_spent DESC, 
    lis.total_revenue ASC
LIMIT 50;
