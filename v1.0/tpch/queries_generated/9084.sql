WITH TotalSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
        AND l.l_returnflag = 'N'
    GROUP BY 
        n.n_name
),
SupplierStats AS (
    SELECT 
        s.s_name AS supplier_name,
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name, s.s_nationkey
),
RankedSuppliers AS (
    SELECT 
        ss.supplier_name,
        ss.supplied_parts,
        ss.total_supply_cost,
        ROW_NUMBER() OVER (ORDER BY ss.total_supply_cost DESC) AS rank
    FROM 
        SupplierStats ss
)
SELECT 
    ts.nation_name,
    ts.total_revenue,
    rs.supplier_name,
    rs.supplied_parts,
    rs.total_supply_cost
FROM 
    TotalSales ts
JOIN 
    RankedSuppliers rs ON ts.nation_name = (
        SELECT n.n_name
        FROM nation n
        WHERE n.n_nationkey = rs.s_nationkey
        LIMIT 1
    )
WHERE 
    rs.rank <= 5
ORDER BY 
    ts.total_revenue DESC, rs.total_supply_cost DESC;
