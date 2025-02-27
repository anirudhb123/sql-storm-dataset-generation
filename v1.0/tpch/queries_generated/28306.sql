WITH PartSupplierStats AS (
    SELECT 
        p.p_partkey,
        RTRIM(LTRIM(p.p_name)) AS trimmed_name,
        COUNT(ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
), 
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierRegionStats AS (
    SELECT 
        n.n_nationkey,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
        SUM(s.s_acctbal) AS total_account_balance
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_nationkey, r.r_name
)
SELECT 
    p.p_partkey,
    p.trimmed_name,
    p.supplier_count,
    p.total_available_qty,
    p.avg_supply_cost,
    c.c_custkey,
    c.c_name,
    c.total_orders,
    c.total_spent,
    r.total_suppliers,
    r.total_account_balance
FROM 
    PartSupplierStats p
LEFT JOIN 
    CustomerOrderStats c ON p.supplier_count > 5
LEFT JOIN 
    SupplierRegionStats r ON r.total_suppliers > 10
WHERE 
    p.avg_supply_cost < 1000
ORDER BY 
    p.total_available_qty DESC, 
    c.total_spent ASC;
