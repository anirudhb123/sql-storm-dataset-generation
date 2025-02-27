WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate) AS order_rank,
        COALESCE(MAX(l.l_extendedprice) OVER (PARTITION BY o.o_orderkey), 0) AS max_lineprice
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey
),
NationInfo AS (
    SELECT 
        n.n_nationkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_balance,
        DENSE_RANK() OVER (ORDER BY SUM(s.s_acctbal) DESC) AS nation_rank
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey
)
SELECT 
    r.r_regionkey,
    r.r_name,
    COALESCE(ni.total_balance, 0) AS nation_balance,
    COUNT(ri.o_orderkey) AS total_orders,
    SUM(ri.o_totalprice) AS total_revenue,
    AVG(ss.avg_supply_cost) AS avg_supply_cost
FROM 
    region r
LEFT JOIN 
    nation_info ni ON r.r_regionkey = ni.n_nationkey
LEFT JOIN 
    RankedOrders ri ON ni.n_nationkey = (
        SELECT 
            n.n_nationkey 
        FROM 
            customer c 
        INNER JOIN 
            nation n ON c.c_nationkey = n.n_nationkey 
        WHERE 
            c.c_custkey = ri.o_custkey
        LIMIT 1
    )
LEFT JOIN 
    SupplierStats ss ON ss.total_supply_cost > (
        SELECT 
            AVG(ps.ps_supplycost) 
        FROM 
            partsupp ps 
        WHERE 
            ps.ps_availqty IS NOT NULL
    )
WHERE 
    (SUM(ri.o_totalprice) IS NOT NULL OR COUNT(ri.o_orderkey) > 10)
GROUP BY 
    r.r_regionkey, r.r_name, ni.total_balance 
HAVING 
    nation_balance > 1000 AND total_orders > 0
ORDER BY 
    r.r_regionkey DESC, total_revenue DESC;
