WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) as rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_quantity,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(l.l_quantity) > 100
)
SELECT 
    c.c_custkey,
    c.c_name,
    COALESCE(SUM(pd.total_quantity), 0) AS total_quantity_ordered,
    COALESCE(SUM(pd.avg_price), 0) AS average_price,
    rs.s_name AS top_supplier
FROM 
    CustomerOrders c
LEFT JOIN 
    PartDetails pd ON c.order_count > 5
LEFT JOIN 
    RankedSuppliers rs ON rs.rank = 1
WHERE 
    c.total_spent > 1000.00
GROUP BY 
    c.c_custkey, c.c_name, rs.s_name
ORDER BY 
    total_quantity_ordered DESC, average_price DESC;
