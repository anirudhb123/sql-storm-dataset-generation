WITH FilteredParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        p.p_retailprice, 
        p.p_comment
    FROM 
        part p
    WHERE 
        p.p_size between 1 AND 20
        AND p.p_retailprice > 100.00
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        s.s_acctbal
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (
            SELECT 
                AVG(s_acctbal) 
            FROM 
                supplier 
            WHERE 
                s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name LIKE 'A%')
        )
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 5
)
SELECT 
    f.p_name, 
    f.p_brand, 
    f.p_type, 
    f.p_retailprice, 
    s.s_name AS supplier_name, 
    c.c_name AS customer_name, 
    co.order_count
FROM 
    FilteredParts f
JOIN 
    partsupp ps ON f.p_partkey = ps.ps_partkey
JOIN 
    SupplierDetails s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    CustomerOrders c ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = ps.ps_partkey)
WHERE 
    f.p_comment LIKE '%special%'
ORDER BY 
    f.p_retailprice DESC, c.order_count ASC;
