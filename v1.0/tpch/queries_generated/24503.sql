WITH RankedSuppliers AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        DENSE_RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS SupplierRank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_expense,
        COUNT(DISTINCT l.l_linenumber) AS line_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(SUM(CASE WHEN rs.SupplierRank = 1 THEN ps.ps_supplycost END), 0) AS cheapest_supplier_cost,
    COALESCE(MAX(co.line_count), 0) AS max_lines_ordered,
    CASE 
        WHEN SUM(l.l_quantity) IS NULL THEN 'No Orders'
        ELSE CONCAT('Total Quantity: ', SUM(l.l_quantity))
    END AS order_summary,
    r.r_name AS region_name
FROM 
    part p
LEFT JOIN 
    RankedSuppliers rs ON p.p_partkey = rs.ps_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    customer c ON l.l_suppkey = c.c_custkey
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey 
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    CustomerOrders co ON c.c_custkey = co.o_custkey
GROUP BY 
    p.p_partkey, p.p_name, r.r_name
HAVING 
    COALESCE(SUM(l.l_extendedprice), 0) > 10000
ORDER BY 
    p.p_partkey ASC 
UNION ALL 
SELECT 
    NULL AS p_partkey,
    'Total' AS p_name,
    SUM(ps.ps_supplycost) AS cheapest_supplier_cost,
    MAX(line_count) AS max_lines_ordered,
    'Aggregate Summary' AS order_summary,
    NULL AS region_name
FROM 
    CustomerOrders;
