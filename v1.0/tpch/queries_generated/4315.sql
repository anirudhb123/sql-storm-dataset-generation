WITH CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierParts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_quantity
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name
    FROM 
        CustomerOrders
    WHERE 
        total_spent > 10000
),
RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        RANK() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
)
SELECT 
    hc.c_name, 
    sp.s_name, 
    rp.p_name, 
    rp.price_rank, 
    (sp.total_quantity * rp.price_rank) AS calculated_value
FROM 
    HighValueCustomers hc
LEFT JOIN 
    lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = hc.c_custkey)
LEFT JOIN 
    SupplierParts sp ON sp.s_suppkey = l.l_suppkey
INNER JOIN 
    RankedParts rp ON rp.p_partkey = l.l_partkey
WHERE 
    l.l_discount > 0.1 AND sp.total_quantity IS NOT NULL
ORDER BY 
    calculated_value DESC
LIMIT 100;
