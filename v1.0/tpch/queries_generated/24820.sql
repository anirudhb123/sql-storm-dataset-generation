WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_totalprice > 100.00
),
NationCounts AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_name
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty * 1.0) AS total_cost
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_availqty IS NOT NULL
    GROUP BY 
        s.s_suppkey
)
SELECT 
    r.n_name AS region_name,
    r.customer_count,
    COALESCE(s.total_cost, 0) AS supplier_total_cost,
    STRING_AGG(DISTINCT CASE 
        WHEN o.o_orderdate = '1995-01-01' AND o.o_orderstatus <> 'O' THEN 'Special Order' 
        ELSE CAST(o.o_orderkey AS VARCHAR)
    END, ', ') AS relevant_orders,
    AVG(CASE 
        WHEN l.l_discount >= 0.1 THEN l.l_extendedprice * (1 - l.l_discount) 
        ELSE NULL 
    END) AS average_discounted_price,
    SUM(l.l_quantity) AS total_quantity,
    COUNT(DISTINCT CASE 
        WHEN l.l_returnflag = 'Y' THEN l.l_orderkey 
    END) AS returned_orders
FROM 
    region r 
LEFT JOIN 
    NationCounts n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    RankedOrders o ON n.n_name = (SELECT n1.n_name FROM nation n1 WHERE n1.n_regionkey = r.r_regionkey AND n1.n_nationkey = o.o_orderkey % 3) 
LEFT JOIN 
    lineitem l ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    SupplierStats s ON s.s_suppkey = l.l_suppkey
WHERE 
    r.r_name LIKE 'A%' 
    OR n.customer_count IS NULL
GROUP BY 
    r.n_name, r.customer_count, s.total_cost
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY 
    total_quantity DESC, region_name
LIMIT 50;
