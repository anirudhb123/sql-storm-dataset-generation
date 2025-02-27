WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        s.s_comment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 5000
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cp.c_name,
    cp.total_orders,
    cp.total_spent,
    rp.p_name AS top_part_name,
    rp.p_retailprice AS top_part_price,
    hs.s_name AS high_value_supplier_name,
    hs.s_acctbal AS high_value_supplier_balance
FROM 
    CustomerOrderSummary cp
JOIN 
    RankedParts rp ON cp.total_orders > 5
JOIN 
    HighValueSuppliers hs ON cp.total_spent > 10000
WHERE 
    rp.price_rank = 1
ORDER BY 
    cp.total_spent DESC, hs.s_acctbal DESC;
