WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 0
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders)
),
OrderLineDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_quantity) AS total_quantity,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Finished'
            WHEN o.o_orderstatus = 'P' THEN 'Pending'
            ELSE 'Unknown'
        END AS order_summary,
        od.total_quantity,
        od.distinct_parts
    FROM 
        orders o
    JOIN 
        OrderLineDetails od ON o.o_orderkey = od.o_orderkey
)
SELECT 
    c.c_custkey AS customer_key,
    c.c_name AS customer_name,
    COALESCE(rs.s_name, 'N/A') AS best_supplier,
    fo.order_summary,
    fo.total_quantity,
    fo.distinct_parts
FROM 
    CustomerOrders co
JOIN 
    customer c ON co.c_custkey = c.c_custkey
LEFT JOIN 
    RankedSuppliers rs ON rs.supplier_rank = 1
LEFT JOIN 
    FilteredOrders fo ON fo.o_orderkey = (SELECT o.o_orderkey
                                           FROM orders o 
                                           WHERE o.o_custkey = c.c_custkey 
                                           ORDER BY o.o_orderdate DESC 
                                           LIMIT 1)
WHERE 
    c.c_acctbal IS NOT NULL
ORDER BY 
    total_quantity DESC, customer_name ASC
FETCH FIRST 100 ROWS ONLY;
