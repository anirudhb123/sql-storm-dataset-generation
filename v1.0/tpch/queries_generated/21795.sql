WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
ActiveOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O' AND
        o.o_orderdate >= DATEADD(day, -30, CURRENT_DATE)
),
NationStatements AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(o.o_totalprice) AS total_orders_value
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(MIN(r.s_name), 'No Suppliers') AS supplier_name,
    ns.n_name AS nation_name,
    ns.customer_count,
    ns.total_orders_value,
    AVG(l.l_quantity) AS avg_line_item_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    COUNT(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN l.l_orderkey END) AS returned_orders,
    MAX(CASE WHEN l.l_shipmode = 'AIR' THEN l.l_tax ELSE NULL END) AS max_air_tax
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers r ON ps.ps_suppkey = r.s_suppkey AND r.supplier_rank = 1
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    ActiveOrders o ON l.l_orderkey = o.o_orderkey
JOIN 
    NationStatements ns ON ns.customer_count > 10
WHERE 
    p.p_retailprice BETWEEN 10.00 AND 100.00
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, ns.n_name, ns.customer_count
HAVING 
    SUM(l.l_extendedprice) > 5000.00
ORDER BY 
    total_sales DESC, p.p_partkey
FETCH FIRST 50 ROWS ONLY;
