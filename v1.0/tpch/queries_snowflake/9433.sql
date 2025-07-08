
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank,
        n.n_nationkey
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey 
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_regionkey, 
        r.r_name, 
        COUNT(rs.s_suppkey) AS top_supplier_count
    FROM 
        region r 
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey 
    JOIN 
        RankedSuppliers rs ON n.n_nationkey = rs.n_nationkey 
    WHERE 
        rs.supplier_rank <= 5 
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    r.r_name AS region_name, 
    ts.top_supplier_count, 
    SUM(c.c_acctbal) AS total_account_balance
FROM 
    TopSuppliers ts 
JOIN 
    region r ON ts.r_regionkey = r.r_regionkey 
JOIN 
    supplier s ON s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey) 
JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
GROUP BY 
    r.r_name, ts.top_supplier_count
ORDER BY 
    total_account_balance DESC, region_name;
