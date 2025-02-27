WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
LineItemAnalysis AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS item_count,
        MAX(l.l_shipdate) AS latest_shipdate
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
),
OrderSummary AS (
    SELECT 
        r.o_orderkey,
        ra.o_orderdate,
        la.total_revenue,
        la.item_count,
        COALESCE(su.total_supply_cost, 0) AS total_supply_cost,
        DENSE_RANK() OVER (ORDER BY la.total_revenue DESC) AS revenue_rank
    FROM 
        RankedOrders ra
    JOIN 
        LineItemAnalysis la ON ra.o_orderkey = la.l_orderkey
    LEFT JOIN 
        SupplierStats su ON su.unique_parts_supplied > 5
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.total_revenue,
    o.item_count,
    o.total_supply_cost,
    CASE 
        WHEN o.total_supply_cost IS NULL THEN 'No Supplies'
        WHEN o.total_supply_cost < 500 THEN 'Low Supply Cost'
        ELSE 'High Supply Cost'
    END AS supply_cost_status
FROM 
    OrderSummary o
WHERE 
    o.revenue_rank <= 10
    AND EXISTS (
        SELECT 
            1
        FROM 
            customer c
        WHERE 
            c.c_custkey IN (
                SELECT o_custkey FROM orders WHERE o_orderkey = o.o_orderkey
            )
            AND c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
    )
ORDER BY 
    o.total_revenue DESC, 
    o.o_orderdate;
