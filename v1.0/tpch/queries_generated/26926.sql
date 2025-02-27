WITH PartSupplier AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_suppkey,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT(s.s_name, ' supplies ', p.p_name) AS supplier_part_info
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        CONCAT(c.c_name, ' placed order #', o.o_orderkey) AS customer_order_info
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
),
LineitemDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_linenumber) AS item_count,
        CONCAT('Order #', l.l_orderkey, ' contains ', COUNT(l.l_linenumber), ' items') AS order_info
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    ps.supplier_part_info,
    co.customer_order_info,
    ld.order_info,
    ld.total_revenue,
    ld.item_count
FROM 
    PartSupplier ps
JOIN 
    CustomerOrders co ON ps.p_partkey = (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = ps.s_suppkey LIMIT 1)
JOIN 
    LineitemDetails ld ON ld.l_orderkey = co.o_orderkey
WHERE 
    ps.ps_availqty > 0 AND co.o_totalprice > 1000
ORDER BY 
    ps.s_name, co.o_orderkey;
