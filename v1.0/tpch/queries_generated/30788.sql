WITH RECURSIVE RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rank
    FROM 
        supplier s
), 
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
PartSupplySummary AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name AS supplier_name,
    cs.c_name AS customer_name,
    cs.total_spent,
    COALESCE(sup.total_available, 0) AS available_quantity,
    COALESCE(sup.total_cost, 0) AS total_supply_cost,
    CASE 
        WHEN cs.order_count > 5 THEN 'High'
        WHEN cs.order_count BETWEEN 1 AND 5 THEN 'Medium'
        ELSE 'Low'
    END AS customer_order_level
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey AND s.rank <= 3
LEFT JOIN 
    CustomerOrderSummary cs ON cs.c_custkey = (SELECT o.o_custkey 
                                               FROM orders o 
                                               WHERE o.o_orderkey IN 
                                                (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey)
                                               ORDER BY o.o_orderdate DESC LIMIT 1)
LEFT JOIN 
    PartSupplySummary sup ON p.p_partkey = sup.ps_partkey
WHERE 
    p.p_retailprice > (SELECT AVG(p_sub.p_retailprice) 
                        FROM part p_sub 
                        WHERE p_sub.p_container = p.p_container)
ORDER BY 
    total_spent DESC, p.p_name ASC;
