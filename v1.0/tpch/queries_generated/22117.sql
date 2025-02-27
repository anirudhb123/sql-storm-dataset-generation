WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rank_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL
),

HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (
            SELECT AVG(o2.o_totalprice) 
            FROM orders o2 
            WHERE o2.o_orderdate < CURRENT_DATE
        )
),

NationSupplierCount AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        COUNT(DISTINCT s.s_suppkey) > 0
)

SELECT 
    r.r_name, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(DISTINCT li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
    MAX(ns.supplier_count) AS max_suppliers,
    COUNT(DISTINCT ns.n_nationkey) AS unique_nations
FROM 
    HighValueOrders o
JOIN 
    lineitem li ON o.o_orderkey = li.l_orderkey
LEFT JOIN 
    (SELECT 
        p.p_type, 
        ns.supplier_count,
        ROW_NUMBER() OVER (ORDER BY ns.supplier_count DESC) as rn
     FROM 
        NationSupplierCount ns 
     INNER JOIN 
        part p ON p.p_partkey = ns.n_nationkey) sub ON o.o_orderkey = sub.p_type
RIGHT JOIN 
    region r ON r.r_regionkey = COALESCE(
        (SELECT DISTINCT n.n_regionkey 
         FROM nation n 
         LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey 
         WHERE s.s_suppkey IS NOT NULL LIMIT 1), 0)
WHERE 
    sub.rn IS NULL OR sub.supplier_count > 5
GROUP BY 
    r.r_name
HAVING 
    SUM(li.l_quantity) > (
        SELECT AVG(l2.l_quantity) 
        FROM lineitem l2 
        WHERE l2.l_shipdate BETWEEN '1995-01-01' AND CURRENT_DATE
    )
ORDER BY 
    total_revenue DESC
LIMIT 10;
