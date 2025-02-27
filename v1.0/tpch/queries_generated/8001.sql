WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ps.ps_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, ps.ps_partkey, p.p_name, p.p_brand, p.p_type
), 
OrderDetails AS (
    SELECT 
        o.o_custkey,
        o.o_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2021-01-01' AND o.o_orderdate < DATE '2022-01-01'
)
SELECT 
    rp.r_name AS supplier_region,
    sp.s_name AS supplier_name,
    SUM(sp.total_available_qty) AS total_qty_supplied,
    SUM(od.l_extendedprice * (1 - od.l_discount)) AS total_revenue,
    COUNT(DISTINCT od.o_orderkey) AS total_orders
FROM 
    region rp
JOIN 
    nation n ON rp.r_regionkey = n.n_regionkey
JOIN 
    supplier sp ON n.n_nationkey = sp.s_nationkey
JOIN 
    SupplierParts sp ON sp.s_suppkey = sp.s_suppkey
JOIN 
    OrderDetails od ON sp.ps_partkey = od.l_partkey
GROUP BY 
    rp.r_name, sp.s_name
HAVING 
    total_revenue > 1000000
ORDER BY 
    total_revenue DESC;
