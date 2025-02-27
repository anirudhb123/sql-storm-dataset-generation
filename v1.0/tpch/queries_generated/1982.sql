WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
), 
TopSuppliers AS (
    SELECT 
        r.s_suppkey,
        r.s_name,
        r.s_acctbal
    FROM 
        RankedSuppliers r
    WHERE 
        r.Rank <= 3
), 
TotalLineItems AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_quantity) AS total_quantity,
        COUNT(DISTINCT l.l_orderkey) AS total_orders
    FROM 
        lineitem l
    GROUP BY 
        l.l_partkey
), 
PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)

SELECT 
    pd.p_partkey,
    pd.p_name,
    COALESCE(t.suppliers, 'No Suppliers') AS suppliers,
    pd.total_supply_cost,
    tl.total_quantity,
    tl.total_orders
FROM 
    PartDetails pd
LEFT JOIN 
    (SELECT 
        p.p_partkey,
        STRING_AGG(ts.s_name, ', ') AS suppliers
     FROM 
        TopSuppliers ts
     JOIN 
        partsupp ps ON ts.s_suppkey = ps.ps_suppkey
     JOIN 
        part p ON ps.ps_partkey = p.p_partkey
     GROUP BY 
        p.p_partkey) t ON pd.p_partkey = t.p_partkey
LEFT JOIN 
    TotalLineItems tl ON pd.p_partkey = tl.l_partkey
WHERE 
    pd.total_supply_cost IS NOT NULL 
    AND (tl.total_orders > 5 OR tl.total_quantity IS NOT NULL)
ORDER BY 
    pd.total_supply_cost DESC, 
    tl.total_orders DESC;
