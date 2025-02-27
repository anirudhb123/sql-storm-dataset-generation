WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rank
    FROM 
        supplier s
), 
HighValueParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.custkey
    HAVING 
        COUNT(o.o_orderkey) >= 5
), 
FilteredLineItems AS (
    SELECT 
        l.orderkey,
        l.partkey,
        AVG(l.discount) AS avg_discount
    FROM 
        lineitem l
    WHERE 
        l.returnflag = 'N' AND l.discount BETWEEN 0.01 AND 0.10
    GROUP BY 
        l.orderkey, l.partkey
)

SELECT 
    p.p_name,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    COALESCE(c.c_name, 'No Customer') AS customer_name,
    lp.avg_discount,
    hvp.total_value,
    rp.rank
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers rp ON ps.ps_suppkey = rp.s_suppkey
LEFT JOIN 
    HighValueParts hvp ON hvp.ps_partkey = p.p_partkey
LEFT JOIN 
    FilteredLineItems lp ON lp.partkey = p.p_partkey
LEFT JOIN 
    CustomerOrders c ON c.c_custkey = ps.ps_suppkey
WHERE 
    p.p_size BETWEEN 1 AND 10 
    AND (p.p_tradeprice IS NULL OR p.p_retailprice > p.p_tradeprice)
ORDER BY 
    p.p_name, hvp.total_value DESC, rp.rank
LIMIT 50;
