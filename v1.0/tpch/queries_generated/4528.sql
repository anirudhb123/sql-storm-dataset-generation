WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) as ranking
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
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
DiscountSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_discounted_price
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    co.c_custkey,
    co.c_name,
    COALESCE(co.total_orders, 0) AS total_orders,
    COALESCE(co.total_spent, 0) AS total_spent,
    rs.s_name AS top_supplier,
    rs.s_acctbal AS top_supplier_balance,
    ds.total_discounted_price
FROM 
    CustomerOrders co
LEFT JOIN 
    RankedSuppliers rs ON rs.ranking = 1
LEFT JOIN 
    DiscountSummary ds ON ds.l_orderkey = co.c_custkey
WHERE 
    (co.total_orders > 5 OR co.total_spent > 1000)
    AND ds.total_discounted_price IS NOT NULL
ORDER BY 
    co.total_spent DESC;
