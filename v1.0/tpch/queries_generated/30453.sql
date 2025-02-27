WITH RECURSIVE PriceTrend AS (
    SELECT 
        p_partkey, 
        p_name, 
        p_retailprice, 
        1 AS price_level 
    FROM 
        part 
    WHERE 
        p_retailprice IS NOT NULL
    UNION ALL
    SELECT 
        p.partkey, 
        p.p_name, 
        p.p_retailprice * 1.05 AS p_retailprice, 
        pt.price_level + 1 
    FROM 
        part p 
    JOIN 
        PriceTrend pt ON p.p_partkey = pt.p_partkey 
    WHERE 
        pt.price_level < 3
), 
SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        SUM(ol.l_extendedprice * (1 - ol.l_discount)) AS revenue, 
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem ol ON o.o_orderkey = ol.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    r.r_name, 
    COUNT(DISTINCT n.n_nationkey) AS nation_count, 
    AVG(ps.total_supply_cost) AS average_supply_cost, 
    SUM(od.revenue) AS total_revenue,
    AVG(pt.p_retailprice) AS average_price_increase
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplierStats ps ON n.n_nationkey = ps.s_suppkey
LEFT JOIN 
    OrderDetails od ON n.n_nationkey = od.o_orderkey
LEFT JOIN 
    PriceTrend pt ON ps.s_suppkey = pt.p_partkey
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_name
HAVING 
    total_revenue > (SELECT AVG(total_revenue) FROM OrderDetails)
ORDER BY 
    average_supply_cost DESC;
