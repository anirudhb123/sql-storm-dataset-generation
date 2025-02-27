WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' AND o.o_totalprice > 1000
    GROUP BY 
        c.c_custkey, c.c_name
), SuspiciousParts AS (
    SELECT 
        p.p_partkey,
        p.p_mfgr,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_mfgr
    HAVING 
        COUNT(DISTINCT ps.ps_suppkey) < 2
)
SELECT 
    r.r_name,
    s.s_name,
    s.total_supply_cost,
    c.c_name,
    c.total_spent
FROM 
    RankedSuppliers s
FULL OUTER JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    HighValueCustomers c ON c.total_spent > COALESCE(NULLIF(s.total_supply_cost, 0), 1) * 0.1
JOIN 
    SuspiciousParts sp ON sp.p_partkey = s.s_suppkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    s.supplier_rank = 1 AND 
    (s.total_supply_cost IS NOT NULL OR c.total_spent IS NOT NULL)
ORDER BY 
    r.r_name ASC, s.total_supply_cost DESC, c.total_spent DESC;
