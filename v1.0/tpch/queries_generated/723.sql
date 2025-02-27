WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
),
SupplierAggregate AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerRegion AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_nationkey,
        n.n_regionkey,
        r.r_name
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        r.r_name IS NOT NULL
)
SELECT 
    cr.r_name,
    COUNT(DISTINCT co.o_orderkey) AS total_orders,
    SUM(co.o_totalprice) AS total_revenue,
    AVG(co.o_totalprice) AS avg_order_value,
    MAX(sa.total_supply_cost) AS max_supply_cost
FROM 
    CustomerRegion cr
LEFT JOIN 
    RankedOrders co ON cr.c_custkey = co.o_custkey
LEFT JOIN 
    SupplierAggregate sa ON sa.ps_partkey IN (
        SELECT 
            l.l_partkey 
        FROM 
            lineitem l
        WHERE 
            l.l_orderkey = co.o_orderkey
    )
WHERE 
    cr.n_regionkey IS NOT NULL
GROUP BY 
    cr.r_name
ORDER BY 
    total_revenue DESC
FETCH FIRST 10 ROWS ONLY;
