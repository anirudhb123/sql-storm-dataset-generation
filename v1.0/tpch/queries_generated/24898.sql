WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank_by_acctbal
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL AND 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value, 
        COUNT(DISTINCT l.l_partkey) AS part_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        order_value > 1000 AND 
        part_count >= (SELECT COUNT(DISTINCT ps.ps_partkey) 
                        FROM partsupp ps 
                        WHERE ps.ps_availqty > 0)
),
CompleteOrderDetails AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_linenumber) AS line_item_count,
        SUM(l.l_extendedprice) AS total_price,
        COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice ELSE 0 END), 0) AS returns_total,
        SUM(CASE WHEN l.l_shipmode = 'AIR' THEN l.l_quantity ELSE NULL END) AS air_ship_qty,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice) DESC) AS order_rank
    FROM 
        orders o
    LEFT OUTER JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
)
SELECT 
    c.c_custkey, 
    c.c_name, 
    SUM(cv.order_value) AS total_value,
    MAX(d.total_price) AS max_order_value,
    SUM(CASE WHEN h.part_count > 5 THEN 1 ELSE 0 END) AS high_value_order_count,
    GROUP_CONCAT(DISTINCT r.r_name) AS region_names
FROM 
    customer c
LEFT JOIN 
    HighValueOrders hv ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = hv.o_orderkey)
LEFT JOIN 
    CompleteOrderDetails d ON hv.o_orderkey = d.o_orderkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    RankedSuppliers s ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = (SELECT TOP 1 p.p_partkey FROM part p WHERE p.p_mfgr = 'Manufacturer' ORDER BY p.p_retailprice DESC) LIMIT 1)
WHERE 
    c.c_acctbal IS NOT NULL
GROUP BY 
    c.c_custkey, c.c_name
HAVING 
    total_value > (SELECT AVG(total_value) FROM (SELECT SUM(order_value) AS total_value FROM HighValueOrders GROUP BY o_orderkey) AS avg_totals)
ORDER BY 
    high_value_order_count DESC, total_value DESC;
