WITH RankedSuppliers AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.custkey
)
SELECT 
    p.p_name,
    p.p_brand,
    COALESCE(r.s_name, 'No Supplier') AS supplier_name,
    COALESCE(r.acctbal, 0) AS supplier_acctbal,
    co.total_orders,
    co.total_spent,
    DENSE_RANK() OVER (ORDER BY p.p_retailprice DESC) AS price_rank
FROM 
    part p
LEFT JOIN 
    RankedSuppliers r ON p.p_partkey = r.ps_partkey AND r.rn = 1
LEFT JOIN 
    CustomerOrders co ON co.c_custkey = (
        SELECT c.c_custkey 
        FROM customer c 
        ORDER BY c.c_acctbal DESC 
        LIMIT 1
    )
WHERE 
    p.p_retailprice BETWEEN 50 AND 200
AND 
    EXISTS (
        SELECT 1 
        FROM lineitem l 
        WHERE l.l_partkey = p.p_partkey 
        AND l.l_shipdate >= CURRENT_DATE - INTERVAL '90 DAYS'
    )
ORDER BY 
    p.p_retailprice DESC;
