WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
),
SupplierAggregation AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_totalprice,
    COALESCE(f.total_revenue, 0) AS total_revenue,
    COALESCE(s.total_supplycost, 0) AS total_supplycost,
    r.o_orderdate,
    CASE 
        WHEN r.o_totalprice > 1000 THEN 'High Value'
        ELSE 'Standard Value'
    END AS order_value_category
FROM 
    RankedOrders r
LEFT JOIN 
    FilteredLineItems f ON r.o_orderkey = f.l_orderkey
LEFT JOIN 
    SupplierAggregation s ON EXISTS (
        SELECT 1
        FROM lineitem l
        WHERE l.l_orderkey = r.o_orderkey
        AND l.l_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_retailprice > 50)
    )
WHERE 
    r.order_rank <= 10
ORDER BY 
    r.o_orderdate DESC, r.o_totalprice DESC;
