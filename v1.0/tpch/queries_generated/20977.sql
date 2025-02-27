WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) as price_rank
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 10
),
SupplierAggregate AS (
    SELECT 
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.custkey
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name, 
        r.r_name,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY n.n_name) AS nation_rank
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        n.n_name IS NOT NULL
)
SELECT 
    rp.p_name,
    ca.c_name,
    ns.r_name,
    ns.nation_rank,
    ca.order_count,
    ca.total_spent,
    COALESCE(sa.total_supply_cost, 0) AS total_cost,
    CASE 
        WHEN ca.order_count > 0 THEN (ca.total_spent / ca.order_count)
        ELSE NULL
    END AS avg_order_value,
    CASE 
        WHEN rp.price_rank = 1 THEN 'Top Price'
        ELSE 'Not Top Price'
    END AS price_status
FROM 
    RankedParts rp
JOIN 
    CustomerOrders ca ON rp.p_partkey = ANY(ARRAY(
        SELECT l.l_partkey
        FROM lineitem l
        WHERE l.l_extendedprice > 100
    ))
LEFT JOIN 
    SupplierAggregate sa ON rp.p_partkey = ANY(ARRAY(
        SELECT ps.ps_partkey
        FROM partsupp ps
        WHERE ps.ps_availqty IS NULL OR ps.ps_supplycost < 50
    ))
JOIN 
    NationRegion ns ON ns.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = ca.c_custkey)
WHERE 
    rp.p_retailprice IS NOT NULL
    AND ca.order_count > 5
ORDER BY 
    rp.p_name, ns.r_name;
