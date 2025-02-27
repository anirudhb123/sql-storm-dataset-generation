WITH CTE_Supplier_Summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CTE_Customer_Orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
CTE_Region_Nations AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(n.n_nationkey) AS nation_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
),
cross_comparison AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(c.total_spent, 0) AS customer_spending,
        COALESCE(s.total_cost, 0) AS supplier_cost,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY c.custkey) AS rn
    FROM 
        CTE_Customer_Orders c
    FULL OUTER JOIN 
        CTE_Supplier_Summary s ON c.c_custkey = s.s_suppkey
)
SELECT 
    cust.c_custkey,
    cust.c_name,
    cust.customer_spending,
    supplier.s_suppkey,
    supplier.s_name,
    COALESCE(cust.customer_spending, 0) - COALESCE(supplier.supplier_cost, 0) AS net_balance,
    r.nation_count
FROM 
    cross_comparison cust 
FULL OUTER JOIN 
    CTE_Region_Nations r ON cust.rn = r.nation_count
WHERE 
    (cust.customer_spending IS NOT NULL OR supplier_cost IS NOT NULL)
    AND (net_balance > 1000 OR net_balance < -1000)
ORDER BY 
    CASE 
        WHEN cust.customer_spending IS NOT NULL THEN 1
        WHEN supplier.supplier_cost IS NOT NULL THEN 2
        ELSE 3
    END,
    cust.c_name DESC;
