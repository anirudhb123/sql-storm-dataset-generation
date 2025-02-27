WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        * 
    FROM 
        RankedSuppliers 
    WHERE 
        rn <= 3
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        CASE 
            WHEN l.l_discount > 0 THEN (l.l_extendedprice * (1 - l.l_discount)) 
            ELSE l.l_extendedprice 
        END AS adjusted_price
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate < CURRENT_DATE - INTERVAL '30 days'
)
SELECT 
    p.p_name,
    SUM(CASE 
            WHEN l.l_returnflag = 'R' THEN l.l_quantity
            ELSE 0 
        END) AS returned_quantity,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    (SELECT COUNT(*) 
     FROM TopSuppliers ts 
     WHERE ts.s_suppkey IN (
         SELECT ps.ps_suppkey 
         FROM partsupp ps 
         WHERE ps.ps_partkey = p.p_partkey
     )) AS supplier_count,
    AVG(co.total_spent) AS avg_customer_spending
FROM 
    part p
LEFT JOIN 
    FilteredLineItems l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    CustomerOrders co ON o.o_custkey = co.c_custkey
WHERE 
    (p.p_size BETWEEN 1 AND 10 OR p.p_container IS NULL)
    AND p.p_retailprice IN (SELECT DISTINCT ps.ps_supplycost FROM partsupp ps WHERE ps.ps_availqty > 0)
GROUP BY 
    p.p_name
HAVING 
    SUM(l.l_quantity) IS NOT NULL
    AND COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    returned_quantity DESC, 
    avg_customer_spending DESC
LIMIT 10;
