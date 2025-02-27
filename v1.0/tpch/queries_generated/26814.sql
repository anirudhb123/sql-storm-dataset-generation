WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        p.p_name,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
TopSuppliers AS (
    SELECT 
        s_name,
        p_name,
        ps_supplycost
    FROM 
        RankedSuppliers
    WHERE 
        rn = 1
),
CustomerOrders AS (
    SELECT 
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate ASC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
)
SELECT 
    cs.c_name AS customer_name,
    cs.o_orderkey AS order_key,
    cs.o_totalprice AS total_price,
    ts.s_name AS supplier_name,
    ts.p_name AS part_name,
    ts.ps_supplycost AS supply_cost,
    cs.order_rank
FROM 
    CustomerOrders cs
JOIN 
    lineitem li ON cs.o_orderkey = li.l_orderkey
JOIN 
    TopSuppliers ts ON li.l_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_name = ts.p_name)
WHERE 
    cs.order_rank <= 5
ORDER BY 
    cs.c_name, cs.o_orderdate;
