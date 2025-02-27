WITH CustomerTotal AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSupply AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        ct.total_spent
    FROM 
        CustomerTotal ct
    JOIN 
        customer c ON ct.c_custkey = c.c_custkey
    WHERE 
        ct.total_spent > 10000
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        pp.total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        PartSupply pp ON ps.ps_partkey = pp.ps_partkey
)
SELECT 
    r.r_name AS region_name,
    np.n_name AS nation_name,
    COUNT(DISTINCT hvc.c_custkey) AS high_value_customer_count,
    SUM(spd.total_supply_cost) AS total_supplier_cost,
    AVG(ct.total_spent) AS average_customer_spending
FROM 
    region r
LEFT JOIN 
    nation np ON r.r_regionkey = np.n_regionkey
LEFT JOIN 
    HighValueCustomers hvc ON hvc.c_nationkey = np.n_nationkey
LEFT JOIN 
    SupplierPartDetails spd ON spd.s_suppkey IN (
        SELECT s.s_suppkey 
        FROM supplier s 
        WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
    )
JOIN 
    CustomerTotal ct ON ct.c_custkey = hvc.c_custkey
GROUP BY 
    r.r_name, np.n_name
HAVING 
    COUNT(DISTINCT hvc.c_custkey) > 0
ORDER BY 
    total_supplier_cost DESC, region_name;
