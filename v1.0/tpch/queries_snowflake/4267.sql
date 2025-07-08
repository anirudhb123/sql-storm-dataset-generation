
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_availability,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1997-06-01'
        AND l.l_shipdate < DATE '1997-12-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    COALESCE(f.net_revenue, 0) AS net_revenue,
    COALESCE(s.total_supply_value, 0) AS supplier_value,
    CASE 
        WHEN r.o_totalprice > 1000 THEN 'High Value'
        ELSE 'Standard'
    END AS order_value_category
FROM 
    RankedOrders r
LEFT JOIN 
    FilteredLineItems f ON r.o_orderkey = f.l_orderkey
LEFT JOIN 
    SupplierStats s ON s.s_suppkey = (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey
        WHERE l.l_orderkey = r.o_orderkey
        LIMIT 1
    )
WHERE 
    r.order_rank <= 10
ORDER BY 
    r.o_orderdate DESC, net_revenue DESC;
