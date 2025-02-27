WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
), 
HighValueOrders AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.o_orderkey,
        co.o_orderdate,
        co.order_total
    FROM 
        CustomerOrders co
    WHERE 
        co.order_total > 1000.00
), 
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey, p.p_name, p.p_brand, p.p_type
)

SELECT 
    DISTINCT 
    co.c_name AS customer_name,
    co.o_orderkey AS order_id,
    co.order_total AS total_price,
    sp.p_name AS part_name,
    sp.total_available AS available_quantity,
    rs.s_name AS supplier_name,
    rs.s_acctbal AS supplier_account_balance
FROM 
    HighValueOrders co
INNER JOIN 
    lineitem l ON co.o_orderkey = l.l_orderkey
LEFT JOIN 
    RankedSuppliers rs ON l.l_suppkey = rs.s_suppkey AND rs.rank <= 2
LEFT JOIN 
    SupplierParts sp ON sp.ps_suppkey = l.l_suppkey 
WHERE 
    l.l_returnflag = 'N' 
    OR l.l_discount > 0.1
    AND sp.total_available IS NOT NULL
ORDER BY 
    co.order_total DESC,
    co.o_orderdate ASC;
