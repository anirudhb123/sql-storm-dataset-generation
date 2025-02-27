WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
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
        r.r_name AS region_name,
        ns.n_name AS nation_name,
        rs.s_name AS supplier_name,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation ns ON rs.s_nationkey = ns.n_nationkey
    JOIN 
        region r ON ns.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank = 1
),
OrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spending
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        o.o_orderdate >= DATEADD(year, -1, GETDATE()) 
    GROUP BY 
        c.c_custkey
)

SELECT 
    cs.region_name,
    cs.nation_name,
    cs.supplier_name,
    cs.total_supply_cost,
    os.order_count,
    os.total_spending,
    COALESCE(os.total_spending / NULLIF(os.order_count, 0), 0) AS avg_spending_per_order
FROM 
    HighCostSuppliers cs
LEFT JOIN 
    OrderStats os ON cs.s_supplier_name = os.customer_name
ORDER BY 
    cs.total_supply_cost DESC, os.total_spending DESC;
