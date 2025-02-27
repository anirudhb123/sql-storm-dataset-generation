WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
),
PartSupplierInfo AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(ps.ps_supplycost) AS total_supply_cost, 
        AVG(ps.ps_availqty) AS avg_avail_qty
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
    GROUP BY 
        o.o_orderkey
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    psi.total_supply_cost,
    psi.avg_avail_qty,
    od.total_order_value,
    CASE 
        WHEN od.total_order_value IS NULL THEN 'No Orders'
        WHEN od.total_order_value > 5000 THEN 'High Value Order'
        ELSE 'Regular Order'
    END AS order_category
FROM 
    PartSupplierInfo psi
LEFT JOIN 
    RankedSuppliers s ON psi.p_partkey = s.s_suppkey 
LEFT JOIN 
    OrderDetails od ON psi.p_partkey = od.o_orderkey
WHERE 
    (psi.total_supply_cost IS NOT NULL OR s.rnk IS NOT NULL)
    AND (od.total_order_value IS NULL OR od.total_order_value < 10000)
ORDER BY 
    COALESCE(psi.avg_avail_qty, 0) DESC, 
    psi.total_supply_cost DESC 
LIMIT 100
UNION
SELECT 
    0 AS p_partkey, 
    'Total' AS p_name, 
    'NULL' AS supplier_name, 
    SUM(total_supply_cost), 
    AVG(avg_avail_qty) / NULLIF(COUNT(p_partkey), 0) AS avg_avail_qty,
    SUM(total_order_value) 
FROM 
    PartSupplierInfo psi 
LEFT JOIN 
    OrderDetails od ON psi.p_partkey = od.o_orderkey
WHERE 
    psi.p_partkey IS NOT NULL;
