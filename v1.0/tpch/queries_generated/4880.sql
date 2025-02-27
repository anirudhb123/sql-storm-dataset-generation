WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice > 0
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '2023-01-01' 
        AND l.l_shipdate < '2023-12-31'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    ps.s_name AS supplier_name,
    ps.total_avail_qty,
    ps.total_supply_value,
    cp.c_name AS customer_name,
    co.total_orders,
    co.avg_order_value,
    rp.p_name AS top_priced_part,
    rp.p_retailprice AS retail_price,
    lis.net_revenue AS order_net_revenue
FROM 
    SupplierSummary ps
LEFT JOIN 
    CustomerOrders co ON ps.total_supply_value > 100000
LEFT JOIN 
    RankedParts rp ON rp.rn = 1
LEFT JOIN 
    LineItemSummary lis ON lis.l_orderkey IN (SELECT DISTINCT o.o_orderkey FROM orders o WHERE o.o_totalprice > 100)
WHERE 
    ps.total_avail_qty IS NOT NULL
    AND co.avg_order_value IS NOT NULL
    AND (rp.p_brand LIKE 'Brand%' OR rp.p_brand IS NULL)
ORDER BY 
    ps.total_supply_value DESC, co.total_orders DESC
LIMIT 50;
