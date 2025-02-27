WITH SupplierCost AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 0
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name
    FROM 
        SupplierCost s
    WHERE 
        s.total_cost > (SELECT AVG(total_cost) FROM SupplierCost)
),
FinalReport AS (
    SELECT 
        C.c_name AS customer_name,
        COALESCE(S.s_name, 'No Supplier') AS supplier_name,
        C.total_orders,
        C.avg_order_value,
        S.total_cost AS supplier_cost
    FROM 
        CustomerOrders C
    LEFT JOIN 
        HighValueSuppliers S ON EXISTS (
            SELECT 1 FROM lineitem l
            WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = C.c_custkey)
            AND l.l_suppkey = S.s_suppkey
        )
)
SELECT 
    *,
    CASE 
        WHEN supplier_cost IS NULL THEN 'NA'
        ELSE FORMAT(supplier_cost, 'C')
    END AS formatted_supplier_cost,
    RANK() OVER (ORDER BY avg_order_value DESC) AS customer_rank
FROM 
    FinalReport
WHERE 
    total_orders > 0
ORDER BY 
    customer_rank;
