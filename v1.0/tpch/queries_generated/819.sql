WITH CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        RANK() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey
),
SupplierPartAvailability AS (
    SELECT 
        s.s_suppkey,
        COUNT(ps.ps_partkey) AS available_parts,
        SUM(ps.ps_availqty) AS total_quantity
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    c.c_name,
    c.c_custkey,
    cod.total_spent,
    cod.order_count,
    spa.s_suppkey,
    spa.available_parts,
    spa.total_quantity
FROM 
    CustomerOrderDetails cod
LEFT JOIN 
    nation n ON cod.c_custkey = n.n_nationkey
LEFT JOIN 
    SupplierPartAvailability spa ON cod.order_count > 5 AND spa.available_parts > 0
WHERE 
    cod.rank_spent = 1
ORDER BY 
    cod.total_spent DESC, c.c_name ASC
FETCH FIRST 10 ROWS ONLY;
