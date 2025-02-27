WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal,
        n.n_name
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.rank = 1 AND rs.s_suppkey = n.n_nationkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_discount) OVER (PARTITION BY o.o_orderkey) AS total_discount
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'F') 
        AND l.l_returnflag IS NULL
),
PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        MAX(ps.ps_availqty) AS max_avail_qty
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
)
SELECT 
    n.r_name,
    COUNT(DISTINCT o.o_orderkey) AS high_value_orders_count,
    AVG(hv.o_totalprice) AS avg_order_value,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    SUM(COALESCE(ps.total_supply_cost, 0)) AS total_supply_cost
FROM 
    region n
LEFT JOIN 
    nation na ON n.r_regionkey = na.n_regionkey
LEFT JOIN 
    TopSuppliers ts ON na.n_nationkey = ts.s_suppkey
LEFT JOIN 
    HighValueOrders hv ON ts.s_suppkey = hv.o_orderkey
LEFT JOIN 
    PartSupplierInfo ps ON hv.o_totalprice > ps.total_supply_cost
WHERE 
    n.r_name LIKE 'N%' 
GROUP BY 
    n.r_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
    AND SUM(COALESCE(ps.total_supply_cost, 0)) > 1000
ORDER BY 
    high_value_orders_count DESC, 
    avg_order_value DESC;
