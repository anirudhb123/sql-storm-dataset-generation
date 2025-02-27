WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
SupplierQuantities AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        partsupp ps
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price, 
        COUNT(DISTINCT l.l_partkey) AS part_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_brand, 
    COALESCE(rq.top_supplier, 'No Supplier') AS top_supplier,
    sq.total_avail_qty,
    od.total_price,
    COALESCE(od.part_count, 0) AS part_count,
    (SELECT COUNT(*) FROM customer c WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000) AS customer_count
FROM 
    part p
LEFT JOIN 
    (SELECT 
         s_suppkey, 
         s_name AS top_supplier 
     FROM 
         RankedSuppliers 
     WHERE 
         rn = 1) rq ON rq.s_suppkey = (SELECT ps.ps_suppkey 
                                        FROM partsupp ps 
                                        WHERE ps.ps_partkey = p.p_partkey 
                                        ORDER BY ps.ps_supplycost ASC 
                                        LIMIT 1)
LEFT JOIN 
    SupplierQuantities sq ON sq.ps_partkey = p.p_partkey
LEFT JOIN 
    OrderDetails od ON od.o_orderkey = (SELECT MIN(o.o_orderkey) 
                                         FROM orders o 
                                         WHERE o.o_orderstatus = 'O')
WHERE 
    p.p_retailprice IS NOT NULL 
    AND p.p_size BETWEEN 5 AND 20
    AND NOT EXISTS (SELECT 1 FROM lineitem l 
                    WHERE l.l_partkey = p.p_partkey 
                    AND l.l_discount IS NULL)
ORDER BY 
    p.p_partkey;
