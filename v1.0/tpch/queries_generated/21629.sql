WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 10 AND 100
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        COALESCE(NULLIF(SUM(ps.ps_supplycost), 0), 1) AS supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerPurchases AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_purchase
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N' OR l.l_returnflag IS NULL
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name,
    COUNT(DISTINCT cp.c_custkey) AS unique_customers,
    COUNT(DISTINCT hp.p_partkey) AS high_value_parts,
    SUM(cp.total_purchase) AS total_spent_by_customers,
    AVG(CASE WHEN s.s_nationkey IS NOT NULL THEN sd.supply_cost ELSE NULL END) AS avg_supply_cost
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    HighValueCustomers hc ON n.n_nationkey = hc.c_custkey
LEFT JOIN 
    RankedParts hp ON hc.total_spent > hp.p_retailprice
LEFT JOIN 
    SupplierDetails sd ON sd.s_nationkey = n.n_nationkey
LEFT JOIN 
    CustomerPurchases cp ON cp.c_custkey = hc.c_custkey
WHERE 
    r.r_name IS NOT NULL AND hc.total_spent IS NOT NULL
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT hc.c_custkey) > 0 AND 
    avg_supply_cost IS NOT NULL
ORDER BY 
    r.r_name DESC;
