WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
), 
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
    HAVING 
        SUM(o.o_totalprice) > 10000
), 
SupplierPartInfo AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        SUM(ps.ps_supplycost) AS total_supplycost,
        COUNT(*) AS supply_count
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_suppkey
    HAVING 
        SUM(ps.ps_supplycost) IS NOT NULL
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    hs.c_name AS high_value_customer,
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    SUM(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount) ELSE l.l_extendedprice END) AS net_revenue,
    s.s_name AS supplier_name,
    s.rn,
    CASE 
        WHEN p.p_retailprice IS NULL THEN 'Price Unavailable' 
        ELSE 'Price Available' 
    END AS price_status,
    COALESCE((SELECT COUNT(*) FROM lineitem l WHERE l.l_partkey = p.p_partkey AND l.l_returnflag = 'R'), 0) AS return_count
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    RankedSuppliers s ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_nationkey = s.s_nationkey)
LEFT JOIN 
    HighValueCustomers hs ON hs.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = s.s_nationkey)
LEFT JOIN 
    SupplierPartInfo spi ON spi.ps_partkey = p.p_partkey
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, hs.c_name, s.s_name, s.rn
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 0 AND
    (p.p_retailprice BETWEEN 10 AND 100 OR p.p_size IS NULL)
ORDER BY 
    net_revenue DESC, p.p_partkey;
