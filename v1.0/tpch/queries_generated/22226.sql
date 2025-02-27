WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_comment,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2022-01-01'
        AND o.o_totalprice IS NOT NULL
),
ValidParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_container,
        CASE 
            WHEN p.p_retailprice > 100 THEN 'Expensive'
            WHEN p.p_retailprice BETWEEN 50 AND 100 THEN 'Moderate'
            ELSE 'Cheap'
        END AS price_category
    FROM 
        part p
    WHERE 
        p.p_size IS NOT NULL
        AND p.p_comment NOT LIKE '%fragile%'
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
TopNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        COUNT(DISTINCT s.s_suppkey) > 1
),
OrderSummaries AS (
    SELECT 
        r.o_orderkey,
        COUNT(DISTINCT l.l_partkey) AS items_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        MAX(rank) AS max_order_rank
    FROM 
        RankedOrders r
    JOIN 
        lineitem l ON r.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        r.o_orderkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    pa.total_available,
    o.items_count,
    o.total_revenue,
    tn.n_name AS nation_name,
    CASE 
        WHEN o.items_count > 5 THEN 'Large Order'
        ELSE 'Small Order'
    END AS order_size,
    CONCAT('Status: ', CASE WHEN o.total_revenue > 1000 THEN 'Profitable' ELSE 'Revisit' END) AS revenue_status
FROM 
    ValidParts p
JOIN 
    SupplierAvailability pa ON p.p_partkey = pa.ps_partkey
LEFT JOIN 
    OrderSummaries o ON o.items_count IS NOT NULL
LEFT JOIN 
    TopNations tn ON tn.supplier_count IS NOT NULL
WHERE 
    p.price_category = 'Expensive' 
    AND (pa.total_available IS NULL OR pa.total_available > 10)
ORDER BY 
    p.p_retailprice DESC, 
    o.total_revenue DESC NULLS LAST;
