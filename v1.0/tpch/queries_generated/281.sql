WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT 
        si.s_suppkey,
        si.s_name,
        si.total_supply_cost,
        si.part_count,
        RANK() OVER (ORDER BY si.total_supply_cost DESC) AS cost_rank
    FROM 
        SupplierInfo si
    WHERE 
        si.total_supply_cost IS NOT NULL
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
CombinedData AS (
    SELECT 
        c.c_custkey,
        co.order_count,
        co.total_spent,
        hvs.total_supply_cost,
        hvs.part_count
    FROM 
        CustomerOrders co
    JOIN 
        nation n ON n.n_nationkey = (
            SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = co.c_custkey
        )
    LEFT JOIN 
        HighValueSuppliers hvs ON (n.n_nationkey = hvs.s_suppkey)
    WHERE 
        co.total_spent >= 10000
)
SELECT 
    cd.c_custkey,
    cd.order_count,
    cd.total_spent,
    COALESCE(cd.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(cd.part_count, 0) AS part_count
FROM 
    CombinedData cd
WHERE 
    cd.order_count > 5
ORDER BY 
    cd.total_spent DESC, cd.c_custkey
LIMIT 20
OFFSET 0;
