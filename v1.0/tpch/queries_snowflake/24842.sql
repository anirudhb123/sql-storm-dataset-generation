
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
), PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_mfgr, p.p_brand, p.p_type
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name 
    FROM 
        CustomerOrders c
    WHERE 
        c.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
)
SELECT 
    pd.p_partkey,
    pd.p_mfgr,
    pd.p_brand,
    pd.p_type,
    COALESCE(rs.s_name, 'No Supplier') AS supplier_name,
    pd.avg_supplycost,
    pd.supplier_count,
    CASE 
        WHEN hv.c_custkey IS NOT NULL THEN 'High Value' 
        ELSE 'Regular' 
    END AS customer_category
FROM 
    PartDetails pd
LEFT JOIN 
    RankedSuppliers rs ON pd.p_partkey = rs.s_suppkey AND rs.rnk = 1
LEFT JOIN 
    HighValueCustomers hv ON hv.c_custkey IN (
        SELECT o.o_custkey 
        FROM orders o 
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
        WHERE l.l_partkey = pd.p_partkey 
        ORDER BY o.o_totalprice DESC 
        LIMIT 1
    )
WHERE 
    (pd.avg_supplycost IS NOT NULL OR pd.supplier_count > 2)
ORDER BY 
    pd.avg_supplycost DESC, pd.p_partkey;
