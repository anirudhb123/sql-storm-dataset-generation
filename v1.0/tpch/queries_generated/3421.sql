WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= (CURRENT_DATE - INTERVAL '1 year')
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        COUNT(DISTINCT p.p_partkey) AS parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey
    HAVING 
        SUM(ps.ps_availqty) > 1000
),
OrderLineItemStats AS (
    SELECT 
        li.l_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales
    FROM 
        lineitem li
    WHERE 
        li.l_shipdate <= CURRENT_DATE
    GROUP BY 
        li.l_orderkey
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ss.s_name,
    ss.total_avail_qty,
    ols.total_sales
FROM 
    RankedOrders ro
LEFT JOIN 
    SupplierStats ss ON ss.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN lineitem li ON ps.ps_partkey = li.l_partkey 
        WHERE li.l_orderkey = ro.o_orderkey
    )
LEFT JOIN 
    OrderLineItemStats ols ON ols.l_orderkey = ro.o_orderkey
WHERE 
    ro.rank = 1 AND
    (ro.o_totalprice > 5000 OR ols.total_sales IS NOT NULL);
