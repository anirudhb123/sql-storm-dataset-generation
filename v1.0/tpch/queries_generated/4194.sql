WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey 
    WHERE 
        o.o_orderdate BETWEEN DATE '2021-01-01' AND DATE '2021-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
HighestRevenueOrders AS (
    SELECT 
        r.order_key,
        r.o_orderdate,
        r.total_revenue 
    FROM (
        SELECT 
            o.o_orderkey AS order_key,
            o.o_orderdate,
            SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
        FROM 
            orders o
        JOIN 
            lineitem l ON o.o_orderkey = l.l_orderkey
        WHERE 
            l.l_shipdate <= CURRENT_DATE AND l.l_returnflag = 'N'
        GROUP BY 
            o.o_orderkey, o.o_orderdate
    ) r
    WHERE 
        r.total_revenue >= (SELECT AVG(total_revenue) FROM RankedOrders)
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    H.order_key,
    H.o_orderdate,
    H.total_revenue,
    COALESCE(S.s_name, 'N/A') AS supplier_name,
    S.total_available_quantity,
    CASE
        WHEN H.total_revenue > 10000 THEN 'High'
        WHEN H.total_revenue BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS revenue_category
FROM 
    HighestRevenueOrders H
LEFT JOIN 
    SupplierDetails S ON S.total_available_quantity > 100
ORDER BY 
    H.total_revenue DESC;
