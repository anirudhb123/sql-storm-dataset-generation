WITH RankedParts AS (
    SELECT 
        p.*,
        ROW_NUMBER() OVER (PARTITION BY p_type ORDER BY p_retailprice ASC) AS rn,
        MAX(p_retailprice) OVER (PARTITION BY p_type) AS max_price_by_type
    FROM 
        part p
), 
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
), 
CustomerPerformance AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus != 'F' OR o.o_orderstatus IS NULL
    GROUP BY 
        c.c_custkey
)
SELECT 
    rp.p_name,
    rp.p_type,
    ss.part_count,
    ss.total_supply_cost,
    cp.total_spent,
    CASE 
        WHEN cp.total_spent IS NULL THEN 'No Orders'
        WHEN cp.total_spent > 1000 THEN 'High Roller'
        ELSE 'Regular Customer'
    END AS customer_status,
    CASE 
        WHEN rp.max_price_by_type IS NULL THEN 'Unknown'
        WHEN rp.max_price_by_type > 100.00 THEN 'Premium'
        ELSE 'Economical'
    END AS part_pricing_category
FROM 
    RankedParts rp
LEFT JOIN 
    SupplierStats ss ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 0)
LEFT JOIN 
    CustomerPerformance cp ON cp.total_orders > 5
WHERE 
    rp.rn <= 10
  AND 
    (rp.p_retailprice IS NOT NULL OR rp.p_comment LIKE '%important%')
ORDER BY 
    rp.p_type, cp.total_spent DESC NULLS LAST;
