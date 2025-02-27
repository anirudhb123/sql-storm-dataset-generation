WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        DENSE_RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM 
        part p
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.custkey
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_regionkey,
        r.r_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
FinalResult AS (
    SELECT 
        c.c_name AS customer_name,
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        sa.total_avail_qty,
        sa.avg_supply_cost,
        co.order_count,
        co.total_spent,
        CASE 
            WHEN co.total_spent IS NULL THEN 'No Orders'
            WHEN co.total_spent > 1000 THEN 'High Spender'
            ELSE 'Regular Spender'
        END AS spending_category
    FROM 
        CustomerOrders co
    FULL OUTER JOIN RankedParts rp ON co.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_name LIKE '%' || rp.p_name || '%')
    JOIN SupplierAvailability sa ON rp.p_partkey = sa.ps_partkey
    JOIN supplier s ON sa.ps_suppkey = s.s_suppkey
    LEFT JOIN NationRegion nr ON s.s_nationkey = nr.n_nationkey
    WHERE 
        rp.brand_rank <= 5 AND 
        (sa.avg_supply_cost IS NOT NULL OR sa.total_avail_qty > 0)
)
SELECT 
    customer_name,
    supplier_name,
    part_name,
    total_avail_qty,
    avg_supply_cost,
    order_count,
    total_spent,
    spending_category
FROM 
    FinalResult
WHERE 
    (total_avail_qty > 1000 OR total_spent < 500) AND
    (spending_category IS NULL OR spending_category LIKE '%Spender')
ORDER BY 
    total_spent DESC, total_avail_qty ASC;
