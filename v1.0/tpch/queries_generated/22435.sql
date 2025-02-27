WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)
), HighValueParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 1000
), OrdersDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        COUNT(li.l_orderkey) AS line_item_count,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS net_revenue
    FROM 
        orders o
    LEFT JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice
), CustomerPreferences AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS orders_count,
        ARRAY_AGG(DISTINCT c.c_mktsegment) AS preferred_segments
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 3
), PartSupplierLimits AS (
    SELECT 
        p.p_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        SUM(ps.ps_availqty) OVER (PARTITION BY ps.ps_partkey) AS total_part_avail
    FROM 
        partsupp ps
    JOIN 
        part p ON p.p_partkey = ps.ps_partkey
    WHERE 
        ps.ps_availqty IS NOT NULL
)
SELECT 
    r.r_name,
    COALESCE(SUM(CASE WHEN rp.rank <= 3 THEN 1 ELSE 0 END), 0) AS top_suppliers_count,
    COUNT(DISTINCT hvp.p_partkey) AS high_value_parts_count,
    AVG(od.o_totalprice) AS avg_order_price,
    jsonb_agg(DISTINCT cp.preferred_segments) AS customer_segments
FROM 
    region r
LEFT JOIN 
    RankedSuppliers rp ON rp.s_suppkey IN (SELECT ps.ps_suppkey FROM PartSupplierLimits ps WHERE ps.total_part_avail < 500)
LEFT JOIN 
    HighValueParts hvp ON hvp.total_value BETWEEN 500 AND 5000
LEFT JOIN 
    OrdersDetails od ON od.o_totalprice IS NOT NULL
LEFT JOIN 
    CustomerPreferences cp ON cp.orders_count > 3
GROUP BY 
    r.r_name
ORDER BY 
    r.r_name
FETCH FIRST 10 ROWS ONLY;
