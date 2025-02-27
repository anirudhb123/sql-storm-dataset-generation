WITH RECURSIVE CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        1 AS depth
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT 
        co.c_custkey,
        co.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        co.depth + 1
    FROM 
        CustomerOrders co
    JOIN 
        orders o ON co.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' AND
        o.o_orderdate > (
            SELECT MAX(o2.o_orderdate)
            FROM orders o2
            WHERE o2.o_custkey = co.c_custkey AND o2.o_orderkey != co.o_orderkey
        )
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_availqty) > 0
),
RegionalSuppliers AS (
    SELECT 
        n.n_name AS nation_name,
        s.s_name AS supplier_name,
        s.s_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL 
        AND s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
)
SELECT 
    co.c_name AS customer_name,
    co.o_orderkey,
    co.o_orderdate,
    COALESCE(r.nation_name, 'Unknown') AS supplier_nation,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_value,
    ROW_NUMBER() OVER (PARTITION BY co.c_custkey ORDER BY co.o_orderdate DESC) AS order_rank
FROM 
    CustomerOrders co
LEFT JOIN 
    lineitem l ON co.o_orderkey = l.l_orderkey
LEFT JOIN 
    FilteredParts fp ON l.l_partkey = fp.p_partkey
LEFT OUTER JOIN 
    RegionalSuppliers r ON r.supplier_name IN (
        SELECT ps.s_suppliername 
        FROM partsupp ps 
        WHERE ps.ps_availqty > 0 AND ps.ps_partkey = fp.p_partkey
    )
GROUP BY 
    co.c_name, co.o_orderkey, co.o_orderdate, r.nation_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY 
    customer_name, o_orderdate DESC;
