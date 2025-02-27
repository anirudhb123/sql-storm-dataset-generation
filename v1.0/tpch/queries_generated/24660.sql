WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rank_acctbal
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_size,
        (CASE 
            WHEN p.p_size IS NULL THEN 'Unknown Size'
            WHEN p.p_size < 10 THEN 'Small'
            WHEN p.p_size BETWEEN 10 AND 20 THEN 'Medium'
            ELSE 'Large'
        END) AS size_category
    FROM 
        part p
    WHERE 
        p.p_retailprice BETWEEN 50 AND (SELECT MAX(p_retailprice) FROM part) * 0.5
)
SELECT 
    cp.c_custkey,
    cp.c_name,
    fp.p_partkey,
    fp.p_name,
    SUM(li.l_quantity) AS total_quantity,
    AVG(li.l_extendedprice * (1 - li.l_discount)) AS average_price,
    COALESCE(rs.s_name, 'No Supplier') AS supplier_name,
    CASE 
        WHEN COUNT(DISTINCT li.l_orderkey) > 1 THEN 'Frequent Buyer'
        WHEN COUNT(DISTINCT li.l_orderkey) = 1 THEN 'One-time Buyer'
        ELSE 'No Purchases'
    END AS buying_status
FROM 
    CustomerOrders cp 
JOIN 
    lineitem li ON li.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cp.c_custkey)
JOIN 
    FilteredParts fp ON li.l_partkey = fp.p_partkey 
LEFT JOIN 
    RankedSuppliers rs ON fp.p_partkey = rs.ps_partkey AND rs.rank_acctbal = 1
WHERE 
    fp.size_category <> 'Unknown Size'
GROUP BY 
    cp.c_custkey, cp.c_name, fp.p_partkey, fp.p_name, rs.s_name
HAVING 
    SUM(li.l_quantity) > 5 OR COUNT(DISTINCT li.l_orderkey) = 0
ORDER BY 
    total_quantity DESC NULLS LAST;
