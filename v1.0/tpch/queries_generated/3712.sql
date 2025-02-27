WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(month, -6, GETDATE())
),
supplier_parts AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
high_value_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment
    FROM 
        supplier s
    JOIN 
        (SELECT s_nationkey 
         FROM nation 
         WHERE n_name = 'USA') n ON s.s_nationkey = n.s_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
)
SELECT 
    p.p_name,
    p.p_brand,
    rp.o_orderkey,
    rp.o_orderdate,
    rp.o_totalprice,
    COALESCE(sp.total_available, 0) AS total_available,
    COALESCE(sp.avg_supply_cost, 0) AS avg_supply_cost,
    hs.s_name AS high_value_supplier
FROM 
    part p
LEFT JOIN 
    supplier_parts sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN 
    ranked_orders rp ON rp.o_orderkey IN (
        SELECT o_orderkey
        FROM lineitem 
        WHERE l_partkey = p.p_partkey
    )
LEFT JOIN 
    high_value_suppliers hs ON sp.ps_suppkey = hs.s_suppkey
WHERE 
    p.p_retailprice > 100.00
AND 
    (rp.o_orderpriority = 'HIGH' OR rp.o_orderpriority IS NULL)
ORDER BY 
    p.p_name, rp.o_orderdate DESC;
