WITH SupplierPrice AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name AS supplier_name,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost) AS rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        SUM(CASE 
            WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount)
            ELSE 0 
        END) AS total_return
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice
), 
TopSuppliers AS (
    SELECT 
        ps_partkey,
        supplier_name,
        ps_supplycost
    FROM 
        SupplierPrice
    WHERE 
        rank = 1
), 
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        SUM(co.total_return) AS total_returned
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        CustomerOrders co ON o.o_orderkey = co.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cs.c_custkey,
    cs.c_name,
    cs.order_count,
    cs.total_spent,
    cs.total_returned,
    ts.supplier_name,
    ts.ps_supplycost
FROM 
    CustomerSummary cs
JOIN 
    TopSuppliers ts ON cs.c_custkey = (SELECT c.c_custkey FROM customer c ORDER BY cs.total_spent DESC LIMIT 1)
WHERE 
    cs.total_returned IS NOT NULL
ORDER BY 
    cs.total_spent DESC, cs.c_name;
