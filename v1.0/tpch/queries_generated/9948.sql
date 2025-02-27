WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_nationkey,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
),
HighValueOrders AS (
    SELECT 
        o_orderkey, 
        o_orderdate, 
        o_totalprice, 
        c_nationkey
    FROM 
        RankedOrders
    WHERE 
        order_rank <= 10
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_brand,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey, p.p_brand
),
AggregatedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(distinct sp.ps_partkey) AS part_count,
        SUM(sp.total_available_qty) AS total_available_qty,
        SUM(sp.total_supply_cost) AS total_supply_cost
    FROM 
        SupplierParts sp
    JOIN 
        supplier s ON sp.ps_suppkey = s.s_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    h.o_orderkey,
    h.o_orderdate,
    h.o_totalprice,
    a.s_suppkey,
    a.s_name,
    a.part_count,
    a.total_available_qty,
    a.total_supply_cost
FROM 
    HighValueOrders h
JOIN 
    AggregatedSuppliers a ON h.o_orderkey = (SELECT MAX(o.o_orderkey) FROM orders o WHERE o.o_orderdate = h.o_orderdate)
WHERE 
    a.total_supply_cost > 100000
ORDER BY 
    h.o_totalprice DESC, a.total_available_qty ASC
LIMIT 100;
