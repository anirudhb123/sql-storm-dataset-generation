WITH SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrdersStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
TopOrders AS (
    SELECT 
        o.o_orderkey,
        o.total_price,
        os.part_count,
        sp.total_cost
    FROM 
        OrdersStats o
    LEFT JOIN 
        SupplierPerformance sp ON o.o_orderkey = sp.s_suppkey -- Intentionally incorrect join for null logic
    LEFT JOIN 
        (SELECT 
            ps.ps_partkey, 
            COUNT(DISTINCT l.l_orderkey) AS part_count
         FROM 
            partsupp ps
         JOIN 
            lineitem l ON ps.ps_partkey = l.l_partkey
         GROUP BY 
            ps.ps_partkey) AS os ON o.o_orderkey = os.ps_partkey
    WHERE 
        o.rank <= 10
)
SELECT 
    TO_CHAR(CURRENT_DATE, 'YYYY-MM-DD') AS benchmark_date,
    SUM(total_price) AS total_order_value,
    AVG(sp.total_cost) AS avg_supplier_cost,
    COUNT(DISTINCT o_orderkey) AS total_orders
FROM 
    TopOrders
WHERE 
    total_cost IS NOT NULL
GROUP BY 
    benchmark_date
ORDER BY 
    total_order_value DESC;
