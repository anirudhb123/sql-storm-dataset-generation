WITH RECURSIVE SupplyMetrics AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER(PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM 
        partsupp ps
    WHERE 
        ps.ps_availqty > 0
), CustomerPurchases AS (
    SELECT 
        o.o_custkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_purchases,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        orders o 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate <= DATE '2023-12-31'
    GROUP BY 
        o.o_custkey
), HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        cp.total_purchases,
        cp.order_count,
        RANK() OVER (ORDER BY cp.total_purchases DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        CustomerPurchases cp ON c.c_custkey = cp.o_custkey
    WHERE 
        cp.total_purchases > 10000
)
SELECT 
    p.p_name,
    p.p_brand,
    COALESCE(SUM(sm.ps_availqty), 0) AS total_available_qty,
    AVG(sm.ps_supplycost) AS average_supply_cost,
    COUNT(DISTINCT hvc.c_custkey) AS high_value_customer_count,
    MAX(CASE 
        WHEN hvc.purchase_rank <= 5 THEN hvc.total_purchases 
        ELSE NULL 
    END) AS top_purchase_amount
FROM 
    part p
LEFT JOIN 
    SupplyMetrics sm ON p.p_partkey = sm.ps_partkey AND sm.rn = 1
RIGHT JOIN 
    HighValueCustomers hvc ON hvc.total_purchases > p.p_retailprice
WHERE 
    p.p_size BETWEEN 1 AND 50 AND 
    (p.p_comment IS NULL OR p.p_comment NOT LIKE '%defective%')
GROUP BY 
    p.p_name, p.p_brand
HAVING 
    COUNT(*) > 0 
ORDER BY 
    total_available_qty DESC, 
    average_supply_cost ASC;
