WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.order_count,
        co.total_spent,
        CASE 
            WHEN co.total_spent > 10000 THEN 'High'
            WHEN co.total_spent BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low' 
        END AS customer_value_category
    FROM 
        CustomerOrders co
    JOIN 
        customer c ON co.c_custkey = c.c_custkey
),
PopularParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(li.l_quantity) AS total_sold
    FROM 
        part p
    JOIN 
        lineitem li ON p.p_partkey = li.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(li.l_quantity) > 100
),
RegionStats AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(s.s_acctbal) AS total_supplier_balance
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
),
FinalReport AS (
    SELECT 
        hvc.c_name,
        hvc.order_count,
        hvc.total_spent,
        pp.p_name,
        pp.total_sold,
        rs.r_name,
        rs.nation_count,
        rs.total_supplier_balance
    FROM 
        HighValueCustomers hvc
    CROSS JOIN 
        PopularParts pp
    LEFT JOIN 
        RegionStats rs ON hvc.c_custkey % 10 = rs.nation_count % 10
)
SELECT 
    f.c_name,
    f.order_count,
    f.total_spent,
    f.p_name,
    f.total_sold,
    f.r_name,
    f.nation_count,
    f.total_supplier_balance
FROM 
    FinalReport f
WHERE 
    f.total_spent IS NOT NULL
    AND f.total_sold IS NOT NULL
ORDER BY 
    f.total_spent DESC, f.total_sold DESC;
