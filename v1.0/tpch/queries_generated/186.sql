WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank_order
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'F'
),
PopularParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        lineitem l
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(l.l_quantity) > 100
),
SupplierRanked AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name,
        DENSE_RANK() OVER (ORDER BY s.s_acctbal DESC) AS supp_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
)
SELECT 
    p.p_name,
    p.p_brand,
    COALESCE(SUM(l.l_discount), 0) AS total_discount,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    CASE 
        WHEN r.rank_order IS NOT NULL THEN r.o_totalprice / NULLIF(order_count, 0)
        ELSE 0
    END AS avg_order_value
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    RankedOrders r ON r.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierRanked s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    s.supp_rank <= 5 AND 
    p.p_retailprice > 50.00
GROUP BY 
    p.p_name, p.p_brand, r.rank_order, r.o_totalprice
ORDER BY 
    total_discount DESC, avg_order_value DESC;
