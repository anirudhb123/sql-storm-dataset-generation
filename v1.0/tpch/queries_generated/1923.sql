WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    p.p_name,
    p.p_brand,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_sales,
    COALESCE(MAX(rs.s_name), 'No Supplier') AS top_supplier,
    COALESCE(MAX(co.total_spent), 0) AS max_customer_spent
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    RankedSuppliers rs ON p.p_partkey = rs.ps_partkey AND rs.rank = 1
LEFT JOIN 
    CustomerOrders co ON co.c_custkey = (SELECT c.c_custkey 
                                            FROM customer c 
                                            WHERE c.c_nationkey = (SELECT n.n_nationkey 
                                                                   FROM nation n 
                                                                   WHERE n.n_name = 'USA') 
                                            ORDER BY c.c_acctbal DESC 
                                            LIMIT 1)
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand
HAVING 
    total_sales > 1000
ORDER BY 
    total_sales DESC;
