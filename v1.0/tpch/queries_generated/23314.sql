WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 0)
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
HighValueCustomers AS (
    SELECT 
        cs.c_custkey
    FROM 
        CustomerStats cs
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM CustomerStats)
),
SupplierAgg AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_value,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    n.n_name,
    COALESCE(SUM(su.supplier_value), 0) AS total_supplier_value,
    (SELECT COUNT(*) FROM HighValueCustomers) AS high_value_customer_count,
    STRING_AGG(DISTINCT p.p_name, ', ') FILTER (WHERE p.rn <= 5) AS top_products
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierAgg su ON su.s_suppkey = s.s_suppkey
LEFT JOIN 
    RankedParts p ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
WHERE 
    s.s_acctbal IS NOT NULL
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 1
ORDER BY 
    total_supplier_value DESC
LIMIT 10
UNION ALL
SELECT 
    'UNKNOWN' AS n_name,
    SUM(total_spent) AS total_supplier_value,
    NULL AS high_value_customer_count,
    NULL AS top_products
FROM 
    CustomerStats
WHERE 
    c_custkey NOT IN (SELECT c_custkey FROM HighValueCustomers)
AND 
    c_acctbal IS NULL;
