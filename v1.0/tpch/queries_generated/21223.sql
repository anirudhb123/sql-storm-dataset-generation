WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        n.n_name IN (SELECT DISTINCT n_name FROM nation WHERE n_regionkey = 1)
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders)
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice < (SELECT AVG(p_retailprice) FROM part)
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    c.c_name AS customer_name,
    co.order_count,
    co.total_spent,
    p.p_name AS part_name,
    fs.total_avail_qty,
    COALESCE(rs.s_name, 'No Supplier') AS supplier_name,
    CASE 
        WHEN fs.total_avail_qty IS NOT NULL THEN 'Available'
        ELSE 'Unavailable'
    END AS availability_status
FROM 
    CustomerOrders co
JOIN 
    customer c ON co.c_custkey = c.c_custkey
LEFT JOIN 
    FilteredParts fs ON fs.p_partkey IN (SELECT DISTINCT l.l_partkey 
                                          FROM lineitem l 
                                          JOIN orders o ON l.l_orderkey = o.o_orderkey
                                          WHERE o.o_custkey = c.c_custkey)
LEFT JOIN 
    RankedSuppliers rs ON rs.rank = 1 AND rs.s_suppkey = (SELECT ps.ps_suppkey 
                                                            FROM partsupp ps 
                                                            WHERE ps.ps_partkey = fs.p_partkey
                                                            ORDER BY ps.ps_supplycost LIMIT 1)
WHERE 
    co.order_count > 0
ORDER BY 
    co.total_spent DESC, availability_status;
