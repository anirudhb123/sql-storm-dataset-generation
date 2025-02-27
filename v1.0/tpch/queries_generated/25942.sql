WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        p.p_container, 
        p.p_retailprice, 
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rnk
    FROM 
        part p
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        s.s_phone, 
        s.s_acctbal, 
        s.s_comment, 
        np.n_name AS nation_name 
    FROM 
        supplier s 
    JOIN 
        nation np ON s.s_nationkey = np.n_nationkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        customer c 
    JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey 
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
)
SELECT 
    p.p_name, 
    sp.s_name AS supplier_name, 
    sp.nation_name, 
    co.c_name AS customer_name, 
    co.total_order_value, 
    p.p_retailprice, 
    p.p_comment
FROM 
    RankedParts p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    SupplierDetails sp ON ps.ps_suppkey = sp.s_suppkey
JOIN 
    CustomerOrders co ON co.total_order_value > p.p_retailprice
WHERE 
    p.rnk <= 5 AND 
    sp.s_acctbal > 2000 AND 
    p.p_size BETWEEN 10 AND 30
ORDER BY 
    p.p_retailprice DESC, 
    co.total_order_value DESC;
