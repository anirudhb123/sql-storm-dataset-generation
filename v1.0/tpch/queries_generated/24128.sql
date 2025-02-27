WITH RECURSIVE cust_order_hierarchy AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderdate,
        0 AS order_level
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' -- Only active orders

    UNION ALL

    SELECT 
        co.c_custkey, 
        co.c_name, 
        o.o_orderkey, 
        o.o_orderdate,
        co.order_level + 1 
    FROM 
        cust_order_hierarchy co
    JOIN 
        orders o ON co.o_orderkey = o.o_orderkey -- Self-join to find repeat orders
    WHERE 
        o.o_orderstatus IN ('O', 'F') -- Include active and finalized
),
part_supplier_data AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) -- Suppliers with above-average account balance
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    c.c_name AS customer_name, 
    c.c_acctbal AS customer_balance,
    p.p_name AS part_name,
    CASE 
        WHEN p.total_cost > 5000 THEN 'High Cost' 
        ELSE 'Low Cost' 
    END AS cost_category, 
    ROW_NUMBER() OVER (PARTITION BY p.p_name ORDER BY c.c_acctbal DESC) AS rank,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(CASE 
        WHEN li.l_discount > 0 THEN li.l_extendedprice * li.l_discount 
        ELSE 0 
    END) AS total_discounts
FROM 
    customer c 
LEFT JOIN 
    cust_order_hierarchy co ON c.c_custkey = co.c_custkey 
LEFT JOIN 
    lineitem li ON co.o_orderkey = li.l_orderkey
JOIN 
    part_supplier_data p ON li.l_partkey = p.p_partkey
LEFT JOIN 
    supplier s ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
GROUP BY 
    c.c_name, c.c_acctbal, p.p_name, p.total_cost, s.s_name, n.n_name
HAVING 
    SUM(li.l_quantity) > 100 -- Only include customers with significant quantities
ORDER BY 
    c.c_acctbal DESC, p.p_name;
