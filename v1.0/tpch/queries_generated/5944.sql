WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_nationkey,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) as order_rank
    FROM 
        orders o 
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
TopOrders AS (
    SELECT 
        r.o_orderkey, 
        r.o_orderdate, 
        r.o_totalprice,
        n.n_name,
        r.order_rank
    FROM 
        RankedOrders r
    JOIN 
        nation n ON r.c_nationkey = n.n_nationkey
    WHERE 
        r.order_rank <= 5
),
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey, p.p_name, p.p_brand
),
FinalReport AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        n.n_name AS customer_nation,
        p.p_name AS part_name,
        p.p_brand AS brand,
        ps.total_available_qty,
        ps.total_supply_cost
    FROM 
        TopOrders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        PartSupplierDetails ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        part p ON l.l_partkey = p.p_partkey
    JOIN 
        nation n ON o.c_nationkey = n.n_nationkey
)
SELECT 
    fr.o_orderkey,
    fr.o_orderdate,
    fr.o_totalprice,
    fr.customer_nation,
    fr.part_name,
    fr.brand,
    fr.total_available_qty,
    fr.total_supply_cost
FROM 
    FinalReport fr
ORDER BY 
    fr.o_orderdate DESC, 
    fr.o_totalprice DESC
LIMIT 100;
