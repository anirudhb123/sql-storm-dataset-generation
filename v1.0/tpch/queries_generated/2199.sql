WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS SalaryRank
    FROM 
        supplier s
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
PartStatistics AS (
    SELECT 
        p.p_partkey,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        SUM(ps.ps_availqty) AS total_available_qty,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    ps.avg_supply_cost,
    ps.total_available_qty,
    ps.supplier_count,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    c.c_name AS high_value_customer
FROM 
    part p
LEFT JOIN 
    PartStatistics ps ON p.p_partkey = ps.p_partkey
LEFT JOIN 
    RankedSuppliers s ON s.SalaryRank = 1 AND s.s_nationkey IN (SELECT n.n_nationkey FROM nation n JOIN supplier sp ON n.n_nationkey = sp.s_nationkey WHERE sp.s_acctbal > 5000) 
LEFT JOIN 
    HighValueCustomers c ON c.total_spent > 5000
WHERE 
    (ps.total_available_qty IS NOT NULL OR ps.avg_supply_cost > 10.00)
ORDER BY 
    p.p_partkey, s.s_name;
