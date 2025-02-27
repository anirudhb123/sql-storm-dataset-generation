WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '2022-01-01' AND o.o_orderdate < '2023-01-01'
),
TopNationOrders AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(oo.o_totalprice) AS total_revenue,
        COUNT(oo.o_orderkey) AS order_count
    FROM 
        RankedOrders oo
    JOIN 
        nation n ON oo.c_nationkey = n.n_nationkey
    WHERE 
        oo.OrderRank <= 5
    GROUP BY 
        n.n_name
),
SupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_supply_cost
    FROM 
        lineitem l
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        l.l_shipdate >= '2022-01-01' AND l.l_shipdate < '2023-01-01'
    GROUP BY 
        ps.ps_partkey, s.s_suppkey, s.s_name
)
SELECT 
    t.nation_name,
    t.total_revenue,
    t.order_count,
    si.s_name,
    si.total_supply_cost
FROM 
    TopNationOrders t
JOIN 
    SupplierInfo si ON si.ps_partkey IN (
        SELECT 
            p.p_partkey
        FROM 
            part p
        JOIN 
            lineitem l ON p.p_partkey = l.l_partkey
        WHERE 
            l.l_shipdate >= '2022-01-01' AND l.l_shipdate < '2023-01-01'
    )
ORDER BY 
    t.total_revenue DESC,
    si.total_supply_cost DESC;
