WITH RankedSuppliers AS (
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
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
),
CustomerTotalBalance AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        c.c_acctbal
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
    HAVING 
        SUM(o.o_totalprice) IS NULL OR SUM(o.o_totalprice) < c.c_acctbal
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    s.s_name AS supplier_name,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No Orders'
        ELSE 'Orders Exist'
    END AS order_status,
    RANK() OVER (ORDER BY p.p_retailprice DESC) AS price_rank,
    COALESCE((SELECT AVG(ps_availqty) FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey), 0) AS avg_avail_qty,
    RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice) AS brand_rank,
    NULLIF(MAX(cs.total_spent), 0) AS highest_customer_spent
FROM 
    part p
LEFT JOIN 
    RankedSuppliers s ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey ORDER BY ps.ps_supplycost ASC LIMIT 1)
LEFT JOIN 
    CustomerTotalBalance cs ON cs.c_custkey = (SELECT MIN(o.o_custkey) FROM HighValueOrders o WHERE o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey))
WHERE 
    p.p_size < 50 
    AND p.p_comment NOT LIKE '%special%'
    AND (s.rank = 1 OR s.rank IS NULL)
ORDER BY 
    p.p_retailprice DESC, supplier_name, price_rank;
