WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        CASE 
            WHEN c.c_acctbal IS NULL THEN 'Unknown'
            WHEN c.c_acctbal > 5000 THEN 'High'
            ELSE 'Low'
        END AS customer_value
    FROM 
        customer c
)
SELECT 
    r.region_name,
    p.p_name,
    sa.total_avail_qty,
    CTE.total_orders,
    CTE.total_spent,
    COALESCE(ct.c_value, 'No Value') AS customer_segment,
    CASE 
        WHEN p.p_retailprice > 1000 THEN 'Luxury'
        ELSE 'Standard'
    END AS price_category
FROM 
    RankedParts p
LEFT JOIN SupplierAvailability sa ON p.p_partkey = sa.ps_partkey
JOIN CustomerOrders CTE ON CTE.total_spent > 1000
LEFT JOIN HighValueCustomers ct ON CTE.c_custkey = ct.c_custkey
JOIN nation n ON n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey LIMIT 1))
JOIN region r ON r.r_regionkey = n.n_regionkey
WHERE 
    (p.p_retailprice IS NOT NULL OR sa.total_avail_qty IS NULL)
    AND (COALESCE(sa.avg_supply_cost, 0) < 50 OR sa.total_avail_qty IS NULL)
ORDER BY 
    r.region_name,
    p.p_name ASC
LIMIT 50;
