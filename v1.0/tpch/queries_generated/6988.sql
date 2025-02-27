WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS supplier_nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_within_region
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        CASE 
            WHEN SUM(o.o_totalprice) > 10000 THEN 'Platinum' 
            WHEN SUM(o.o_totalprice) BETWEEN 5000 AND 10000 THEN 'Gold'
            ELSE 'Silver'
        END AS customer_tier
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    s.s_name AS supplier_name,
    r.supplier_nation,
    r.total_supply_cost,
    c.c_name AS customer_name,
    c.total_spent,
    c.customer_tier,
    r.rank_within_region
FROM 
    RankedSuppliers r
JOIN 
    HighValueCustomers c ON r.rank_within_region <= 5
WHERE 
    r.total_supply_cost > 50000
ORDER BY 
    r.supplier_nation, r.total_supply_cost DESC, c.total_spent DESC;
