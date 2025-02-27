WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
),
PartStatistics AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        MAX(ps.ps_availqty) AS max_avail_qty
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
FinalBenchmark AS (
    SELECT 
        sp.s_name,
        co.c_name,
        ps.p_name,
        ps.avg_supply_cost,
        ps.max_avail_qty,
        sp.total_parts,
        co.total_orders,
        co.total_spent
    FROM 
        SupplierParts sp
    CROSS JOIN 
        CustomerOrders co
    JOIN 
        PartStatistics ps ON ps.p_partkey = (SELECT ps_partkey FROM partsupp ORDER BY RANDOM() LIMIT 1)
)
SELECT 
    *
FROM 
    FinalBenchmark
ORDER BY 
    total_spent DESC, total_orders DESC
LIMIT 100;
