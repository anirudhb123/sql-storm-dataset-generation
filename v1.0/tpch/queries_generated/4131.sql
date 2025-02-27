WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey 
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), TopCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(r.total_revenue) AS total_spent,
        ROW_NUMBER() OVER (ORDER BY SUM(r.total_revenue) DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        RankedOrders r ON c.c_custkey = r.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(r.total_revenue) > 10000
), SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        COUNT(ps.ps_partkey) AS parts_supplied,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), FinalReport AS (
    SELECT 
        tc.c_name AS customer_name,
        ss.s_name AS supplier_name,
        ss.parts_supplied,
        ss.avg_supply_cost,
        COALESCE(tc.total_spent, 0) AS total_customer_spent
    FROM 
        TopCustomers tc
    FULL OUTER JOIN 
        SupplierStats ss ON ss.parts_supplied > 0
)
SELECT 
    fr.customer_name, 
    fr.supplier_name, 
    fr.parts_supplied, 
    fr.avg_supply_cost, 
    fr.total_customer_spent,
    CASE 
        WHEN fr.total_customer_spent > 50000 THEN 'High Value'
        WHEN fr.total_customer_spent BETWEEN 20000 AND 50000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    FinalReport fr
WHERE 
    fr.total_customer_spent IS NOT NULL
ORDER BY 
    fr.total_customer_spent DESC, fr.parts_supplied DESC;
