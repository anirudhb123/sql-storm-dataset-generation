WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size > 10 AND 
        p.p_retailprice IS NOT NULL
),
NationSupplier AS (
    SELECT 
        n.n_name,
        SUM(s.s_acctbal) AS total_acctbal,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COALESCE(SUM(o.o_totalprice), 0) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus <> 'F' OR o.o_orderstatus IS NULL
    GROUP BY 
        c.c_custkey
)
SELECT 
    np.n_name,
    np.total_acctbal,
    cp.total_spent,
    cp.order_count,
    CASE 
        WHEN cp.total_spent > 5000 THEN 'High Value'
        WHEN cp.total_spent BETWEEN 1000 AND 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    STRING_AGG(DISTINCT rp.p_name ORDER BY rp.rn) AS top_parts
FROM 
    NationSupplier np
LEFT JOIN 
    CustomerOrders cp ON np.n_name = cp.c_custkey::text
LEFT JOIN 
    RankedParts rp ON rp.p_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps
        JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
        WHERE s.s_nationkey = (
            SELECT n.n_nationkey 
            FROM nation n 
            WHERE n.n_name = np.n_name
        )
    )
GROUP BY 
    np.n_name, 
    np.total_acctbal, 
    cp.total_spent, 
    cp.order_count
HAVING 
    SUM(CASE WHEN cp.total_spent IS NULL THEN 1 ELSE 0 END) = 0
ORDER BY 
    np.total_acctbal DESC;
