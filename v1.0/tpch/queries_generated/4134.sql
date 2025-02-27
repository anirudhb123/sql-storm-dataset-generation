WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_per_status
    FROM 
        orders o
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 1000
),
PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_brand,
        ps.ps_supplycost,
        s.s_name,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
LatestLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        l.l_shipmode,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_receiptdate DESC) AS rn
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey, l.l_shipmode
)
SELECT 
    c.c_name,
    COALESCE(cs.total_spent, 0) AS total_spent,
    COUNT(DISTINCT lo.l_orderkey) AS number_of_orders,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS returned_items,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    MAX(roi.o_totalprice) AS max_order_value
FROM 
    customer c
LEFT JOIN 
    CustomerStats cs ON c.c_custkey = cs.c_custkey
LEFT JOIN 
    RankedOrders roi ON roi.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey ORDER BY o.o_orderdate DESC LIMIT 1)
LEFT JOIN 
    LatestLineItems l ON c.c_custkey = l.l_orderkey
LEFT JOIN 
    PartSupplierInfo ps ON ps.rn = 1
WHERE 
    c.c_acctbal IS NOT NULL AND c.c_acctbal > 0
GROUP BY 
    c.c_name, cs.total_spent
HAVING 
    COUNT(DISTINCT lo.l_orderkey) > 5
ORDER BY 
    total_spent DESC, c.c_name;
