WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O'
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS average_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
    GROUP BY 
        ps.ps_partkey
),
TopPart AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(ss.total_available, 0) AS total_available,
        COALESCE(ss.average_cost, 0) AS average_cost,
        (p.p_retailprice - COALESCE(ss.average_cost, 0)) AS price_diff
    FROM 
        part p
    LEFT JOIN 
        SupplierStats ss ON p.p_partkey = ss.ps_partkey
),
OrderLineItem AS (
    SELECT 
        li.l_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        COUNT(DISTINCT li.l_partkey) AS part_count
    FROM 
        lineitem li
    GROUP BY 
        li.l_orderkey
),
FinalResults AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_mktsegment,
        tp.p_name,
        tp.price_diff,
        oli.total_revenue,
        oli.part_count
    FROM 
        RankedOrders ro
    LEFT JOIN 
        TopPart tp ON ro.o_orderkey = (SELECT l_orderkey FROM lineitem WHERE l_linenumber = 1 AND l_orderkey = ro.o_orderkey)
    LEFT JOIN 
        OrderLineItem oli ON ro.o_orderkey = oli.l_orderkey
    WHERE 
        (ro.rank <= 5 OR tp.price_diff > 20)
        AND (ro.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31')
)
SELECT 
    f.o_orderkey,
    f.o_orderdate,
    f.o_totalprice,
    f.c_mktsegment,
    COUNT(f.p_name) AS unique_products_sold,
    SUM(f.total_revenue) AS total_revenue_generated,
    AVG(f.part_count) AS avg_parts_per_order
FROM 
    FinalResults f
GROUP BY 
    f.o_orderkey, f.o_orderdate, f.o_totalprice, f.c_mktsegment
HAVING 
    COUNT(f.p_name) > 0
    AND SUM(f.total_revenue) IS NOT NULL
ORDER BY 
    f.o_orderdate DESC, f.o_totalprice DESC;
