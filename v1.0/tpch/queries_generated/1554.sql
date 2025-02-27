WITH RankedSupplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 5000
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        COALESCE(NULLIF(p.p_brand, ''), 'Unknown') AS p_brand_description
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    ps.ps_availqty,
    ps.ps_supplycost AS supply_cost,
    (SELECT COUNT(DISTINCT o.o_orderkey) 
     FROM orders o 
     WHERE o.o_orderkey IN (SELECT o_orderkey FROM HighValueOrders)) AS high_value_order_count
FROM 
    PartSupplierDetails ps
LEFT JOIN 
    RankedSupplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    HighValueOrders ho ON ho.o_orderkey = ps.ps_partkey
WHERE 
    ps.ps_availqty > 0 AND 
    (s.rnk <= 3 OR s.rnk IS NULL) 
ORDER BY 
    p.p_partkey, s.s_name;
