WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
TotalOrderValue AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate > '1995-01-01' AND l.l_shipdate < '1996-01-01'
    GROUP BY 
        o.o_orderkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_name,
    COALESCE(r.s_name, 'No Supplier') AS supplier_name,
    COALESCE(t.order_count, 0) AS total_orders,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(t.total_value) AS avg_order_value,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_served
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers r ON ps.ps_suppkey = r.s_suppkey AND r.rank = 1
LEFT JOIN 
    CustomerOrders t ON t.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA'))
LEFT JOIN 
    nation n ON n.n_nationkey = (SELECT DISTINCT c.c_nationkey FROM customer c WHERE c.c_custkey = t.c_custkey)
WHERE 
    p.p_retailprice > 100.00 AND
    (ps.ps_availqty IS NULL OR ps.ps_availqty > 10)
GROUP BY 
    p.p_name, r.s_name, t.order_count
ORDER BY 
    avg_order_value DESC;
