
WITH supplier_part_summary AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
), 
region_summary AS (
    SELECT 
        r.r_regionkey,
        COUNT(DISTINCT n.n_nationkey) AS total_nations,
        SUM(s.s_acctbal) AS total_supplier_balance
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_regionkey
), 
order_summary AS (
    SELECT 
        o.o_orderstatus,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderstatus
) 
SELECT 
    r.r_regionkey,
    r.total_nations,
    r.total_supplier_balance,
    s.total_parts,
    s.total_supply_cost,
    o.o_orderstatus,
    o.total_order_value,
    o.total_orders
FROM 
    region_summary r
LEFT JOIN 
    supplier_part_summary s ON s.s_suppkey IN (
        SELECT s.s_suppkey 
        FROM supplier s 
        JOIN nation n ON s.s_nationkey = n.n_nationkey 
        WHERE n.n_regionkey = r.r_regionkey
    )
LEFT JOIN 
    order_summary o ON o.o_orderstatus IN (
        SELECT o.o_orderstatus 
        FROM orders o 
        WHERE EXISTS (
            SELECT 1 
            FROM customer c 
            WHERE c.c_custkey = o.o_custkey 
            AND c.c_nationkey IN (
                SELECT n.n_nationkey 
                FROM nation n 
                WHERE n.n_regionkey = r.r_regionkey
            )
        )
    )
ORDER BY 
    r.r_regionkey, 
    o.o_orderstatus;
