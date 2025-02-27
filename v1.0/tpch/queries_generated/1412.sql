WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ss.total_supply_value
    FROM 
        SupplierStats ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE 
        ss.rank <= 5
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
NationCount AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    cs.c_name,
    cs.total_spent,
    cs.total_orders,
    n.n_name AS nation_name,
    hs.s_name AS high_value_supplier,
    hs.total_supply_value
FROM 
    CustomerSummary cs
LEFT JOIN 
    HighValueSuppliers hs ON cs.total_spent > 10000 AND cs.total_orders > 5
LEFT JOIN 
    nation n ON cs.c_custkey = n.n_nationkey
WHERE 
    (hs.total_supply_value IS NOT NULL OR (cs.total_spent IS NOT NULL AND cs.total_orders > 0))
ORDER BY 
    cs.total_spent DESC, hs.total_supply_value DESC;
