WITH RECURSIVE MonthlyOrders AS (
    SELECT 
        o.orderkey,
        DATE_TRUNC('month', o.orderdate) AS order_month,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.orderkey, DATE_TRUNC('month', o.orderdate)
),
RankedOrders AS (
    SELECT 
        order_month,
        SUM(total_revenue) AS monthly_revenue,
        RANK() OVER (ORDER BY SUM(total_revenue) DESC) AS revenue_rank
    FROM 
        MonthlyOrders
    GROUP BY 
        order_month
),
SupplierWithMaxPrice AS (
    SELECT 
        ps.s_suppkey,
        MAX(p.p_retailprice) AS max_price
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.s_suppkey
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(swm.max_price, 0) AS max_price
    FROM 
        supplier s
    LEFT JOIN 
        SupplierWithMaxPrice swm ON s.s_suppkey = swm.s_suppkey
),
FinalAnalysis AS (
    SELECT 
        rd.order_month,
        rd.monthly_revenue,
        sd.s_name,
        sd.max_price,
        ROW_NUMBER() OVER (PARTITION BY rd.order_month ORDER BY rd.monthly_revenue DESC) AS supplier_rank
    FROM 
        RankedOrders rd
    JOIN 
        SupplierDetails sd ON sd.max_price > 0
)

SELECT 
    fa.order_month,
    fa.monthly_revenue,
    fa.s_name,
    fa.max_price
FROM 
    FinalAnalysis fa
WHERE 
    fa.supplier_rank <= 5 AND
    fa.monthly_revenue > (SELECT AVG(monthly_revenue) FROM RankedOrders)
ORDER BY 
    fa.order_month, fa.monthly_revenue DESC;
