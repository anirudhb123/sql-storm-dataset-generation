WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' 
        AND o.o_orderdate < DATE '2023-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS supplier_nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
FilteredLineItems AS (
    SELECT 
        li.l_orderkey,
        li.l_partkey,
        li.l_quantity,
        li.l_extendedprice,
        li.l_discount,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS revenue
    FROM 
        lineitem li
    WHERE 
        li.l_shipdate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        li.l_orderkey, li.l_partkey, li.l_quantity, li.l_extendedprice, li.l_discount
)
SELECT 
    o.o_orderkey,
    COUNT(DISTINCT li.l_partkey) AS part_count,
    SUM(li.revenue) AS total_revenue,
    s.total_supply_value,
    CASE 
        WHEN SUM(li.revenue) IS NULL THEN 0 
        ELSE SUM(li.revenue) 
    END AS adjusted_revenue
FROM 
    RankedOrders o
LEFT JOIN 
    FilteredLineItems li ON o.o_orderkey = li.l_orderkey
LEFT JOIN 
    SupplierDetails s ON s.s_suppkey = (SELECT ps.ps_suppkey 
                                          FROM partsupp ps 
                                          WHERE ps.ps_partkey = li.l_partkey 
                                          ORDER BY ps.ps_supplycost ASC 
                                          LIMIT 1)
WHERE 
    o.order_rank <= 10
GROUP BY 
    o.o_orderkey, s.total_supply_value
ORDER BY 
    total_revenue DESC, o.o_orderkey;
