WITH PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        p.p_retailprice, 
        p.p_comment,
        CONCAT(p.p_name, ' - ', p.p_brand, ' (Size: ', p.p_size, ')') AS full_description
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
        TRIM(s.s_name) AS trimmed_name
    FROM 
        supplier s
),
CustomerPurchases AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_address, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_address
),
LineitemDetails AS (
    SELECT 
        l.l_orderkey, 
        l.l_partkey, 
        SUM(l.l_quantity) AS total_quantity, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey, l.l_partkey
)
SELECT 
    pd.full_description, 
    sd.trimmed_name, 
    cp.c_name, 
    lp.total_quantity, 
    lp.total_revenue
FROM 
    PartDetails pd
JOIN 
    partsupp ps ON pd.p_partkey = ps.ps_partkey
JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
JOIN 
    LineitemDetails lp ON pd.p_partkey = lp.l_partkey
JOIN 
    CustomerPurchases cp ON cp.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = lp.l_orderkey LIMIT 1)
WHERE 
    pd.p_retailprice > 50.00
ORDER BY 
    total_revenue DESC, 
    pd.p_name ASC;
