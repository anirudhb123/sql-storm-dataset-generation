WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_availqty * ps.ps_supplycost) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type
),
TopParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_mfgr,
        rp.p_brand,
        rp.p_type,
        rp.total_supply_value
    FROM 
        RankedParts rp
    WHERE 
        rp.rank <= 5
),
RegionSupplier AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        r.r_regionkey, r.r_name, s.s_suppkey, s.s_name
),
OrderDetail AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_linenumber) AS total_line_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
)
SELECT 
    tp.p_name,
    tp.p_brand,
    tp.total_supply_value,
    r.r_name AS supplier_region,
    rs.total_available_qty,
    od.total_order_value,
    od.total_line_items
FROM 
    TopParts tp
JOIN 
    RegionSupplier rs ON tp.p_partkey = rs.s_suppkey
JOIN 
    OrderDetail od ON od.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = rs.s_suppkey))
ORDER BY 
    tp.total_supply_value DESC, od.total_order_value DESC;
