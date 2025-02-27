WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
), 
TopSuppliers AS (
    SELECT 
        r.r_name AS region,
        ts.s_name,
        ts.total_supply_cost
    FROM 
        RankedSuppliers ts
    JOIN 
        nation n ON ts.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ts.rank <= 5
)
SELECT 
    r.region,
    COUNT(ts.s_name) AS supplier_count,
    AVG(ts.total_supply_cost) AS avg_supply_cost,
    SUM(ts.total_supply_cost) AS total_supply_cost
FROM 
    TopSuppliers ts
JOIN 
    (SELECT DISTINCT r.r_name FROM region r) r ON ts.region = r.r_name
GROUP BY 
    r.region
ORDER BY 
    total_supply_cost DESC;
