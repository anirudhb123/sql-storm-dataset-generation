WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        1 AS level
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O' AND o.o_orderdate >= '2022-01-01'

    UNION ALL

    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        oh.level + 1
    FROM 
        orders o
    JOIN 
        OrderHierarchy oh ON o.o_custkey = oh.o_orderkey 
    WHERE 
        o.o_orderstatus = 'O'
), RankedSuppliers AS (
    SELECT 
        s.s_name,
        s.s_suppkey,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) as rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name, s.s_suppkey, s.s_nationkey
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), ExceededCust AS (
    SELECT 
        c.c_custkey,
        c.c_name
    FROM 
        CustomerOrders c
    WHERE 
        c.order_count > 5 AND c.total_spent > 1000
), SupplierPartCount AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_container,
    RANK() OVER (ORDER BY p.p_retailprice DESC) AS price_rank,
    COALESCE(sp.supplier_count, 0) AS supplier_count,
    COALESCE(oh.level, 0) AS order_level
FROM 
    part p
LEFT JOIN 
    SupplierPartCount sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN 
    OrderHierarchy oh ON oh.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT ec.c_custkey FROM ExceededCust ec))
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
ORDER BY 
    price_rank DESC, supplier_count ASC
LIMIT 100;
