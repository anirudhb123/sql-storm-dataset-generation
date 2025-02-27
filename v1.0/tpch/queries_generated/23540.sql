WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as supplier_rank
    FROM 
        supplier s
),
PartSales AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    JOIN 
        part p ON l.l_partkey = p.p_partkey
    GROUP BY 
        p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    n.n_name,
    p.p_name,
    ps.ps_availqty,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    COALESCE(total_sales, 0) AS total_sales,
    order_count,
    avg_order_value
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey AND s.supplier_rank <= 3
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    PartSales psales ON p.p_partkey = psales.p_partkey
LEFT JOIN 
    CustomerOrders co ON n.n_nationkey = COALESCE((SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = co.order_count)), n.n_nationkey)
WHERE 
    (COALESCE(order_count, 0) > 50 OR total_sales > 1000.00)
    AND (s.s_suppkey IS NOT NULL OR n.n_regionkey IS NULL)
ORDER BY 
    total_sales DESC, p.p_name ASC
LIMIT 10;
