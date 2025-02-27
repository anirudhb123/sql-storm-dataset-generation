WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
),
OrderDetails AS (
    SELECT 
        ro.o_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
        COUNT(li.l_orderkey) AS num_items,
        AVG(li.l_quantity) AS avg_quantity
    FROM 
        RankedOrders ro
    INNER JOIN 
        lineitem li ON ro.o_orderkey = li.l_orderkey
    WHERE 
        li.l_returnflag = 'N'
    GROUP BY 
        ro.o_orderkey
),
CustomerRank AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        DENSE_RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_costs,
        SUM(li.l_extendedprice) AS total_line_item_values,
        CASE WHEN SUM(li.l_extendedprice) IS NULL THEN 0 ELSE SUM(li.l_extendedprice) END AS line_item_value_with_nulls
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem li ON ps.ps_partkey = li.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
FinalSummary AS (
    SELECT 
        cr.c_name,
        cr.total_spent,
        cr.order_count,
        od.total_sales,
        sp.total_supply_costs
    FROM 
        CustomerRank cr
    LEFT JOIN 
        OrderDetails od ON cr.order_count = od.num_items
    FULL OUTER JOIN 
        SupplierPerformance sp ON sp.total_supply_costs > 1000
    WHERE 
        cr.customer_rank <= 10
)
SELECT 
    COALESCE(c_name, 'No Customer') AS customer_name,
    total_spent,
    COALESCE(order_count, 0) AS order_count,
    COALESCE(total_sales, 0.00) AS total_sales,
    COALESCE(total_supply_costs, 0.00) AS total_supply_costs
FROM 
    FinalSummary
ORDER BY 
    total_spent DESC NULLS LAST;
