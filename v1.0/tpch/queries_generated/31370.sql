WITH RECURSIVE SupplierRank AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
PartCost AS (
    SELECT 
        p.p_partkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
LineitemDetails AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(l.l_partkey) AS item_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    c.c_name,
    COALESCE(co.order_count, 0) AS order_count,
    COALESCE(co.total_spent, 0) AS total_spent,
    SUM(ld.revenue) AS total_revenue,
    COUNT(DISTINCT sr.s_suppkey) AS top_suppliers,
    MAX(pc.total_supply_cost) AS max_supply_cost
FROM 
    customer c
LEFT JOIN 
    CustomerOrders co ON c.c_custkey = co.c_custkey
LEFT JOIN 
    LineitemDetails ld ON ld.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
LEFT JOIN 
    SupplierRank sr ON sr.rank <= 3 AND sr.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN part p ON ps.ps_partkey = p.p_partkey 
        WHERE p.p_brand = 'Brand#23'
    )
LEFT JOIN 
    PartCost pc ON pc.p_partkey IN (
        SELECT l.l_partkey 
        FROM lineitem l 
        WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
    )
WHERE 
    c.c_acctbal IS NOT NULL AND c.c_acctbal > 100.00
GROUP BY 
    c.c_name, co.order_count, co.total_spent
ORDER BY 
    total_revenue DESC
FETCH FIRST 10 ROWS ONLY;
