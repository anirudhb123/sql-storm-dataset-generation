WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
TopRevenueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.total_revenue,
        o.o_orderstatus
    FROM 
        RankedOrders ro
    JOIN 
        orders o ON ro.o_orderkey = o.o_orderkey
    WHERE 
        ro.revenue_rank <= 10
),
SupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_suppkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(ps.ps_supplycost) AS supply_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    T.o_orderkey,
    T.total_revenue,
    T.o_orderstatus,
    PD.p_name,
    PD.supply_count,
    SD.total_supply_cost
FROM 
    TopRevenueOrders T
LEFT JOIN 
    PartDetails PD ON PD.supply_count > 0
LEFT JOIN 
    SupplierDetails SD ON SD.ps_partkey IN (SELECT DISTINCT ps_partkey FROM partsupp WHERE ps_supplycost > 20.00)
WHERE 
    T.total_revenue > (
        SELECT AVG(total_revenue) FROM TopRevenueOrders
    )
ORDER BY 
    T.total_revenue DESC, T.o_orderstatus ASC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
