WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        COUNT(l.l_orderkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND l.l_shipdate >= '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_availqty) AS total_avail
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, p.p_name, p.p_brand
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    COALESCE(hvo.total_value, 0) AS total_order_value,
    COALESCE(hvo.item_count, 0) AS total_item_count,
    sp.p_name AS part_name,
    sp.total_avail AS available_quantity
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    RankedSuppliers s ON n.n_nationkey = s.s_nationkey AND s.rank <= 5
LEFT JOIN 
    HighValueOrders hvo ON hvo.o_custkey IN (
        SELECT c.c_custkey
        FROM customer c
        WHERE c.c_nationkey = n.n_nationkey
    )
LEFT JOIN 
    SupplierParts sp ON s.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        WHERE ps.ps_partkey = sp.ps_partkey
    )
WHERE 
    (hvo.total_value IS NOT NULL OR sp.total_avail > 0)
ORDER BY 
    r.r_name, n.n_name, s.s_name;
