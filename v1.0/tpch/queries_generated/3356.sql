WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_size, 
        p.p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p.p_size ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100.00
), 
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(o.o_orderkey) AS orders_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        c.c_acctbal > 1000.00
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
), 
SupplierAvailability AS (
    SELECT 
        s.s_suppkey, 
        SUM(ps.ps_availqty) AS total_available, 
        COUNT(DISTINCT ps.ps_partkey) AS parts_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
)

SELECT 
    cp.c_name, 
    cp.total_spent, 
    rp.p_name, 
    rp.p_retailprice,
    sa.total_available,
    sa.parts_count
FROM 
    CustomerOrderDetails cp
JOIN 
    RankedParts rp ON cp.total_spent > (SELECT AVG(total_spent) FROM CustomerOrderDetails) 
LEFT JOIN 
    SupplierAvailability sa ON sa.parts_count > 3
WHERE 
    rp.rank <= 5 
    AND EXISTS (
        SELECT 1 
        FROM lineitem l 
        WHERE l.l_extendedprice * (1 - l.l_discount) > 200 
        AND l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cp.c_custkey)
    )
ORDER BY 
    cp.total_spent DESC, 
    rp.p_retailprice ASC;
