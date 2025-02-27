WITH ranked_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_name ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 50
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 10
),
final_result AS (
    SELECT 
        cu.c_name AS customer_name,
        cu.total_orders AS order_count,
        s.s_name AS top_supplier_name,
        s.s_acctbal AS supplier_account_balance
    FROM 
        customer_orders cu
    LEFT JOIN 
        ranked_suppliers s ON s.supplier_rank = 1
    ORDER BY 
        cu.total_orders DESC, supplier_account_balance DESC
)
SELECT 
    customer_name,
    order_count,
    top_supplier_name,
    supplier_account_balance
FROM 
    final_result
WHERE 
    order_count > 5
LIMIT 10;
