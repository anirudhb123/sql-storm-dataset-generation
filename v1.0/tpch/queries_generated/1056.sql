WITH CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey, p.p_name
),
OrderLineDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT l.l_linenumber) AS line_item_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2023-12-31'
    GROUP BY 
        l.l_orderkey
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        DENSE_RANK() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) as supplier_rank
    FROM 
        supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    cus.c_name AS customer_name,
    cus.order_count,
    cus.total_spent,
    sup.s_name AS supplier_name,
    sup.total_available,
    ord.l_orderkey,
    ord.revenue,
    ord.line_item_count,
    CASE WHEN ord.revenue > 1000 THEN 'High Value' ELSE 'Regular Value' END AS order_type,
    RANK() OVER (PARTITION BY cus.c_custkey ORDER BY ord.revenue DESC) AS revenue_rank
FROM 
    CustomerOrderSummary cus
LEFT JOIN OrderLineDetails ord ON cus.order_count > 0 AND ord.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cus.c_custkey)
LEFT JOIN SupplierPartDetails sup ON sup.total_available > 0
WHERE 
    sup.total_available IS NOT NULL
ORDER BY 
    cus.total_spent DESC, ord.revenue DESC;
