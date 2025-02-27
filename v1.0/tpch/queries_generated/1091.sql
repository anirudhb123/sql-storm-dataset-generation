WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
OrderCounts AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.custkey
),
DiscountDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS discounted_price,
        SUM(l.l_discount) AS total_discount
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '2023-01-01' AND l.l_shipdate <= '2023-12-31'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    p.p_name,
    p.p_mfgr,
    r.r_name,
    s.s_name AS top_supplier,
    od.total_orders,
    dd.discounted_price,
    dd.total_discount,
    CASE 
        WHEN dd.total_discount IS NULL THEN 'No Discount'
        ELSE 'Discount Applied'
    END AS discount_status
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey AND s.rank = 1
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    OrderCounts od ON s.s_suppkey = od.c_custkey
LEFT JOIN 
    DiscountDetails dd ON dd.l_orderkey = ps.ps_partkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
ORDER BY 
    discounted_price DESC NULLS LAST;
