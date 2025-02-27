WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_price
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
    AND 
        o.o_orderstatus IN ('O', 'F', 'P')
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(l.l_orderkey) AS sales_count,
        AVG(l.l_extendedprice) AS avg_price,
        SUM(l.l_discount) AS total_discount
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    co.c_custkey,
    co.c_name,
    COALESCE(ro.rank_price, 0) AS order_rank,
    pp.p_partkey,
    pp.p_name,
    pp.sales_count,
    pp.avg_price,
    pp.total_discount,
    sp.supplier_value,
    CASE 
        WHEN pp.sales_count > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS part_status
FROM 
    CustomerOrders co
LEFT JOIN 
    RankedOrders ro ON co.order_count > 3 AND co.total_spent > 1000
INNER JOIN 
    PartDetails pp ON pp.sales_count > 2
LEFT JOIN 
    SupplierParts sp ON sp.supplier_value IS NOT NULL 
WHERE 
    co.c_custkey NOT IN (
        SELECT DISTINCT c.c_custkey 
        FROM customer c 
        WHERE c.c_acctbal < 0
    )
ORDER BY 
    co.c_custkey, pp.p_partkey
OFFSET 100 ROWS
FETCH NEXT 50 ROWS ONLY;

WITH RECURSIVE PartHierarchy AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        1 AS level
    FROM 
        part p
    WHERE 
        p.p_size > 32
    UNION ALL
    SELECT 
        p2.p_partkey,
        CONCAT(ph.p_name, ' -> ', p2.p_name) AS p_name,
        level + 1
    FROM 
        part p2
    JOIN 
        PartHierarchy ph ON ph.p_partkey = p2.p_partkey
)
SELECT 
    p.p_partkey,
    ph.p_name,
    ph.level
FROM 
    PartHierarchy ph
JOIN 
    part p ON ph.p_partkey = p.p_partkey
ORDER BY 
    ph.level DESC;
