WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 1000.00
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        COUNT(DISTINCT l.l_linenumber) AS total_lines,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND l.l_shipdate >= DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
CustomerStats AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    c.c_name AS customer_name,
    os.total_lines AS lines_in_orders,
    os.net_sales AS total_net_sales,
    COALESCE(ss.total_supply_cost, 0) AS supplier_cost,
    cs.total_spent AS customer_expenditure,
    DENSE_RANK() OVER (ORDER BY os.net_sales DESC) AS sales_rank
FROM 
    OrderStats os
JOIN 
    CustomerStats cs ON os.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE cs.c_custkey = o.o_custkey)
LEFT JOIN 
    SupplierStats ss ON ss.num_parts >= 5
WHERE 
    cs.total_spent IS NOT NULL 
    AND os.total_lines > 0
ORDER BY 
    cs.total_spent DESC, sales_rank;
