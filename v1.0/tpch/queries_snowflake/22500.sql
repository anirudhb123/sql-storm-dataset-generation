
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
),
TotalOrders AS (
    SELECT 
        o.o_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
),
NationStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(COALESCE(s.s_acctbal, 0)) AS total_account_balance
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
ComplexQuery AS (
    SELECT 
        ns.n_name,
        ns.supplier_count,
        ns.customer_count,
        ns.total_account_balance,
        COALESCE(tt.total_spent, 0) AS highest_spending_customer
    FROM 
        NationStats ns
    LEFT JOIN 
        TotalOrders tt ON tt.o_custkey = (
            SELECT o.o_custkey 
            FROM orders o
            LEFT JOIN customer c ON o.o_custkey = c.c_custkey
            WHERE c.c_nationkey = ns.n_nationkey
            ORDER BY o.o_totalprice DESC
            LIMIT 1
        )
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_discount) AS average_discount,
    MAX(l.l_tax) AS max_tax,
    CASE
        WHEN COUNT(DISTINCT l.l_orderkey) > 0 THEN 'Orders exist'
        ELSE 'No orders'
    END AS order_status,
    (SELECT COUNT(*) 
     FROM RankedSuppliers rs 
     WHERE rs.rnk = 1 
       AND rs.s_acctbal > p.p_retailprice) AS top_supplier_count
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    p.p_size IN (SELECT DISTINCT CASE 
                                   WHEN p_size % 2 = 0 THEN p_size / 2 
                                   ELSE NULL 
                                  END 
                 FROM part)
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_retailprice
HAVING 
    SUM(l.l_quantity) > (SELECT AVG(l2.l_quantity) FROM lineitem l2)
ORDER BY 
    total_quantity DESC;
