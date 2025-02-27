WITH RECURSIVE SupplyChain AS (
    SELECT 
        ps.partkey,
        ps.suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        1 AS level
    FROM 
        partsupp ps
    WHERE 
        ps.ps_availqty > 0

    UNION ALL

    SELECT 
        ps2.partkey,
        ps2.suppkey,
        ps2.ps_availqty,
        ps2.ps_supplycost,
        sc.level + 1
    FROM 
        partsupp ps2
    JOIN 
        SupplyChain sc ON ps2.suppkey = sc.suppkey
    WHERE 
        ps2.ps_availqty > 0 AND 
        sc.level < 5
),
AggregatedCosts AS (
    SELECT 
        p.p_partkey,
        SUM(sc.ps_supplycost * sc.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT sc.suppkey) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        SupplyChain sc ON p.p_partkey = sc.partkey
    GROUP BY 
        p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_orders,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_name,
    ac.total_supply_cost,
    ac.supplier_count,
    co.total_orders,
    co.order_count,
    p.p_retailprice - COALESCE(ac.total_supply_cost, 0) AS profit_margin,
    CASE
        WHEN co.total_orders IS NULL THEN 'No Orders Yet'
        WHEN co.total_orders < 1000 THEN 'Low Sales'
        ELSE 'Good Sales'
    END AS sales_feedback
FROM 
    part p
LEFT JOIN 
    AggregatedCosts ac ON p.p_partkey = ac.p_partkey
LEFT JOIN 
    CustomerOrders co ON p.p_partkey = co.c_custkey
WHERE 
    p.p_retailprice IS NOT NULL
ORDER BY 
    profit_margin DESC, sales_feedback;
