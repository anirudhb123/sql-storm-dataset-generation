WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        DENSE_RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS region_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS line_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
    COALESCE(AVG(l.l_extendedprice), 0) AS average_price,
    CASE 
        WHEN r.region_rank IS NULL THEN 'No Supplier'
        ELSE rs.total_supply_cost
    END AS top_supplier_cost,
    os.line_count,
    os.total_sales
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    RankedSuppliers rs ON rs.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey ORDER BY ps.ps_supplycost * ps.ps_availqty DESC LIMIT 1)
LEFT JOIN 
    OrderSummary os ON os.o_orderkey = (SELECT o.o_orderkey FROM orders o ORDER BY o.o_orderdate DESC LIMIT 1)
GROUP BY 
    p.p_partkey, p.p_name, r.region_rank
ORDER BY 
    total_quantity DESC, p.p_name ASC
LIMIT 100;
