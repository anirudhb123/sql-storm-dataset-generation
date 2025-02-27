WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rnk,
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.ps_availqty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) >= 1000
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value,
        ROW_NUMBER() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rn
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 5000
)
SELECT 
    r.s_name,
    r.p_name,
    c.c_name,
    c.total_order_value,
    COALESCE(s.ps_availqty, 0) AS available_quantity,
    COALESCE(s.p_retailprice, 0) AS retail_price,
    CASE 
        WHEN s.rnk = 1 THEN 'Best Supplier'
        ELSE 'Other Supplier'
    END AS supplier_rank
FROM 
    RankedSuppliers s
JOIN 
    TopCustomers c ON s.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost = (SELECT MAX(ps2.ps_supplycost) FROM partsupp ps2 WHERE ps2.ps_partkey = s.p_partkey))
WHERE 
    c.rn <= 10
ORDER BY 
    available_quantity DESC, retail_price ASC;
