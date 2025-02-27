WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_within_region
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
OrdersStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS total_lines,
        RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' 
        AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopSuppliers AS (
    SELECT 
        s.s_name,
        s.total_supply_cost,
        r.r_name,
        ROW_NUMBER() OVER (ORDER BY s.total_supply_cost DESC) AS overall_rank
    FROM 
        SupplierStats s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.total_parts > 5
),
CombinedResults AS (
    SELECT 
        ts.s_name,
        ts.total_supply_cost,
        os.total_revenue,
        os.total_lines
    FROM 
        TopSuppliers ts
    LEFT JOIN 
        OrdersStats os ON ts.s_name = os.o_orderkey
)
SELECT 
    cr.s_name,
    cr.total_supply_cost,
    COALESCE(cr.total_revenue, 0) AS total_revenue,
    CASE 
        WHEN cr.total_lines IS NULL THEN 'No Orders'
        ELSE CAST(cr.total_lines AS VARCHAR)
    END AS total_lines,
    RANK() OVER (ORDER BY cr.total_supply_cost DESC) AS supplier_rank
FROM 
    CombinedResults cr
WHERE 
    cr.total_supply_cost > 1000.00
ORDER BY 
    cr.total_supply_cost DESC;
