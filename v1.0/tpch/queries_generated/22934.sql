WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' 
        AND o.o_orderdate < DATE '1996-01-01'
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 100
    GROUP BY 
        s.s_suppkey
),
OrderLineAggregate AS (
    SELECT 
        lo.l_orderkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue,
        COUNT(*) AS line_count
    FROM 
        lineitem lo
    WHERE 
        lo.l_shipdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
    GROUP BY 
        lo.l_orderkey
)
SELECT 
    r.n_name AS nation_name,
    COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
    oa.total_revenue AS total_order_revenue,
    o.order_rank
FROM 
    RankedOrders o
LEFT JOIN 
    OrderLineAggregate oa ON o.o_orderkey = oa.l_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    nation r ON c.c_nationkey = r.n_nationkey
LEFT JOIN 
    SupplierSummary ss ON ss.s_suppkey = (SELECT ps.ps_suppkey 
                                            FROM partsupp ps 
                                            JOIN part p ON ps.ps_partkey = p.p_partkey 
                                            WHERE p.p_size = 20 
                                            ORDER BY ps.ps_supplycost DESC 
                                            LIMIT 1)
WHERE 
    o.o_orderstatus IN ('O', 'F')
    AND (r.n_name IS NOT NULL OR ss.total_supply_cost IS NOT NULL)
ORDER BY 
    total_order_revenue DESC,
    total_supply_cost DESC;
