WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighCostSuppliers AS (
    SELECT 
        s.s_nationkey,
        s.s_name,
        s.total_supply_cost
    FROM 
        RankedSuppliers s
    WHERE 
        s.rank <= 3
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_nationkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' 
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
    HAVING 
        SUM(o.o_totalprice) > 100000
),
JoinedData AS (
    SELECT 
        c.c_name AS customer_name, 
        n.n_name AS nation_name,
        h.total_spent,
        hs.s_name AS supplier_name,
        hs.total_supply_cost
    FROM 
        HighValueCustomers c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN 
        HighCostSuppliers hs ON n.n_nationkey = hs.s_nationkey
)
SELECT 
    jd.customer_name,
    jd.nation_name,
    jd.total_spent,
    COALESCE(jd.supplier_name, 'No supplier') AS supplier_name,
    COALESCE(jd.total_supply_cost, 0) AS total_supply_cost,
    CASE 
        WHEN jd.total_spent > 500000 THEN 'High Value Customer'
        WHEN jd.total_spent > 100000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value
FROM 
    JoinedData jd
WHERE 
    jd.total_spent IS NOT NULL
ORDER BY 
    jd.total_spent DESC;
