WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey
    HAVING 
        total_order_value > 10000
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey, p.p_name, p.p_brand, p.p_type
)
SELECT 
    r.r_name AS region,
    SUM(COALESCE(hv.total_order_value, 0)) AS total_high_value_order,
    COUNT(DISTINCT rsp.s_suppkey) AS count_high_value_suppliers,
    SUM(spd.total_available_qty) AS total_available_quantity
FROM 
    RankedSuppliers rsp
JOIN 
    nation n ON rsp.nation_name = n.n_name
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    HighValueOrders hv ON rsp.s_suppkey IN (SELECT ps.ps_suppkey FROM SupplierPartDetails spd WHERE spd.ps_partkey = l.l_partkey)
LEFT JOIN 
    SupplierPartDetails spd ON rsp.s_suppkey = spd.ps_suppkey
GROUP BY 
    r.r_name
ORDER BY 
    r.r_name ASC;
