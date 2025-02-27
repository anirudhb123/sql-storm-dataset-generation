WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > 100
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        AVG(ps.ps_supplycost) < (SELECT AVG(ps_supplycost) FROM partsupp)
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        c.c_custkey
),
NationsWithNulls AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COALESCE(SUM(ps.ps_supplycost), 0) AS total_supplycost
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        COALESCE(SUM(ps.ps_supplycost), 0) IS NOT NULL
)
SELECT 
    nwn.n_nationkey,
    nwn.n_name,
    COALESCE(hvp.avg_supply_cost, 0) AS avg_part_supply_cost,
    r.s_name AS top_supplier_name,
    COALESCE(co.total_spent, 0) AS customer_total_spent
FROM 
    NationsWithNulls nwn
LEFT JOIN 
    HighValueParts hvp ON hvp.p_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size >= 10)
LEFT JOIN 
    RankedSuppliers r ON nwn.n_nationkey = r.s_nationkey AND r.rnk = 1
LEFT JOIN 
    CustomerOrders co ON co.total_spent > 
        (SELECT AVG(total_spent) FROM CustomerOrders)
ORDER BY 
    nwn.n_nationkey ASC, customer_total_spent DESC
LIMIT 10 OFFSET 5;
