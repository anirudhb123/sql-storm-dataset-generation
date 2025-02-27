WITH RankedSuppliers AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
SupplierDetails AS (
    SELECT 
        r.r_regionkey,
        n.n_nationkey,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
        SUM(s.s_acctbal) AS total_account_balance
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_regionkey, n.n_nationkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(r.s_name, 'No Supplier') AS top_supplier,
    COALESCE(cs.order_count, 0) AS customer_order_count,
    COALESCE(cs.total_spent, 0) AS total_customer_spent,
    sd.total_suppliers,
    sd.total_account_balance,
    CASE 
        WHEN cs.total_spent IS NULL OR cs.total_spent = 0 THEN 'No Orders'
        ELSE 
            CASE 
                WHEN cs.avg_order_value > 500 THEN 'High Value'
                ELSE 'Normal Value'
            END
    END AS customer_order_status
FROM 
    part p
LEFT JOIN 
    RankedSuppliers r ON p.p_partkey = r.ps_partkey AND r.supplier_rank = 1
LEFT JOIN 
    CustomerOrders cs ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey IS NOT NULL))
LEFT JOIN 
    SupplierDetails sd ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_acctbal >= 0))
WHERE 
    p.p_size BETWEEN 1 AND 50
AND 
    (p.p_comment NOT LIKE '%defective%' OR p.p_comment IS NULL)
ORDER BY 
    p.p_partkey DESC
FETCH FIRST 10 ROWS ONLY;
