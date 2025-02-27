WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IS NULL OR o.o_orderdate > '2022-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders)
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS distinct_suppliers,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        COUNT(DISTINCT ps.ps_suppkey) > 3
)
SELECT 
    c.c_name AS customer_name,
    COALESCE(rp.s_name, 'No Supplier') AS supplier_name,
    cp.total_spent,
    sp.total_supply_cost,
    CASE 
        WHEN cp.order_count > 5 THEN 'Frequent Customer'
        ELSE 'Occasional Customer'
    END AS customer_type
FROM 
    CustomerOrders cp
LEFT JOIN 
    RankedSuppliers rp ON rp.supplier_rank = 1
LEFT JOIN 
    SupplierParts sp ON sp.ps_partkey = (SELECT p.p_partkey 
                                          FROM part p 
                                          ORDER BY p.p_retailprice DESC 
                                          LIMIT 1)
WHERE 
    cp.order_count IS NOT NULL
ORDER BY 
    customer_name ASC, total_spent DESC;
