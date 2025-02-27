WITH RankedSuppliers AS (
    SELECT 
        p.p_partkey,
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s1.s_acctbal) FROM supplier s1 WHERE s1.s_nationkey = s.s_nationkey)
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierOrderDetails AS (
    SELECT 
        l.l_orderkey, 
        l.l_partkey,
        s.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        l.l_orderkey, l.l_partkey, s.s_suppkey
)
SELECT 
    cs.c_custkey,
    cs.c_name,
    COALESCE(rp.s_suppkey, -1) AS top_supplier_key,
    rp.s_name AS top_supplier_name,
    cs.total_orders,
    cs.total_spent,
    COALESCE(SUM(sod.total_revenue), 0) AS total_supplier_revenue
FROM 
    CustomerOrderSummary cs
LEFT JOIN 
    RankedSuppliers rp ON cs.c_custkey = (SELECT o.o_custkey 
                                            FROM orders o 
                                            JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
                                            WHERE l.l_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 10)
                                            ORDER BY o.o_orderdate DESC 
                                            LIMIT 1) 
LEFT JOIN 
    SupplierOrderDetails sod ON sod.l_orderkey IN (SELECT o.o_orderkey 
                                                    FROM orders o 
                                                    WHERE o.o_custkey = cs.c_custkey) 
GROUP BY 
    cs.c_custkey, cs.c_name, rp.s_suppkey, rp.s_name
HAVING 
    total_spent > 1000 OR top_supplier_key = -1
ORDER BY 
    total_spent DESC, cs.c_name;
