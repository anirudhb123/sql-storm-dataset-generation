WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_in_nation
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), NationalTotals AS (
    SELECT 
        n.n_regionkey,
        SUM(RS.total_supply_cost) AS national_supply_cost
    FROM 
        RankedSuppliers RS
    JOIN 
        nation n ON RS.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_regionkey
), KeyOrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2022-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
)
SELECT 
    n.r_name,
    KT.o_orderstatus,
    COUNT(DISTINCT KT.o_orderkey) AS num_orders,
    SUM(KT.total_lineitem_value) AS total_revenue,
    NT.national_supply_cost
FROM 
    KeyOrderDetails KT
JOIN 
    NationalTotals NT ON NT.national_supply_cost > 1000000
JOIN 
    region n ON NT.n_regionkey = n.r_regionkey
GROUP BY 
    n.r_name, KT.o_orderstatus
HAVING 
    COUNT(DISTINCT KT.o_orderkey) > 5
ORDER BY 
    n.r_name, total_revenue DESC;
