WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate, 
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2023-12-31'
), 
SupplierParts AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        SUM(ps.ps_availqty) AS total_availability,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, 
        ps.ps_suppkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 0
    GROUP BY 
        c.c_custkey, 
        c.c_name
)

SELECT 
    c.c_name, 
    COUNT(DISTINCT o.o_orderkey) AS order_count, 
    SUM(o.o_totalprice) AS total_spent, 
    COUNT(lp.l_orderkey) AS lineitem_count, 
    p.p_name,
    CASE 
        WHEN s.avg_supply_cost IS NOT NULL THEN s.avg_supply_cost 
        ELSE 0 
    END AS avg_supply_cost,
    CASE 
        WHEN lp.l_discount > 0.2 THEN 'High Discount'
        ELSE 'Regular Discount'
    END AS discount_category
FROM 
    CustomerOrders c
JOIN 
    RankedOrders o ON c.order_count > 5
LEFT JOIN 
    lineitem lp ON lp.l_orderkey IN (SELECT o_orderkey FROM RankedOrders WHERE order_rank = 1)
LEFT JOIN 
    partsupp ps ON lp.l_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierParts s ON ps.ps_suppkey = s.ps_suppkey
LEFT JOIN 
    part p ON p.p_partkey = lp.l_partkey
GROUP BY 
    c.c_name, s.avg_supply_cost, lp.l_discount, p.p_name
HAVING 
    SUM(o.o_totalprice) > 1000
ORDER BY 
    total_spent DESC;
