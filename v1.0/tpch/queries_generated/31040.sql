WITH RECURSIVE CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        1 AS order_level
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= '2023-01-01'
    
    UNION ALL

    SELECT 
        co.c_custkey,
        co.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        co.order_level + 1
    FROM 
        CustomerOrders co
    JOIN 
        orders o ON co.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= '2023-01-01' AND co.order_level < 5
),
PartSummary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    co.c_custkey,
    co.c_name,
    SUM(co.o_totalprice) AS total_spent,
    COUNT(co.o_orderkey) AS number_of_orders,
    p.p_partkey,
    p.p_name,
    ps.total_available,
    ps.avg_supply_cost,
    s.total_parts_supplied,
    s.total_supply_cost,
    s.avg_account_balance
FROM 
    CustomerOrders co
LEFT JOIN 
    lineitem l ON co.o_orderkey = l.l_orderkey
LEFT JOIN 
    PartSummary ps ON l.l_partkey = ps.p_partkey
LEFT JOIN 
    SupplierStats s ON ps.p_partkey IN (
        SELECT ps_partkey FROM partsupp WHERE ps_supplycost = (
            SELECT MAX(ps_supplycost) FROM partsupp WHERE ps_partkey = ps.p_partkey
        )
    )
WHERE 
    co.order_level = 1
GROUP BY 
    co.c_custkey, co.c_name, p.p_partkey, p.p_name, ps.total_available, ps.avg_supply_cost, s.total_parts_supplied, s.total_supply_cost, s.avg_account_balance
HAVING 
    SUM(co.o_totalprice) > 10000
ORDER BY 
    total_spent DESC, co.c_name ASC;
