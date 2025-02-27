WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
MaxOrderValue AS (
    SELECT 
        o.o_custkey,
        MAX(o.o_totalprice) AS max_order
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(mov.max_order, 0) AS max_order_value,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        MaxOrderValue mov ON c.c_custkey = mov.o_custkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, mov.max_order
)
SELECT 
    ci.nation_name,
    ci.region_name,
    COUNT(ci.s_suppkey) AS supplier_count,
    AVG(ci.s_acctbal) AS avg_supplier_balance,
    SUM(cos.total_spent) AS total_customer_spending,
    SUM(CASE WHEN cos.max_order_value > 0 THEN 1 ELSE 0 END) AS customers_with_orders
FROM 
    SupplierInfo ci
JOIN 
    CustomerOrderStats cos ON ci.s_suppkey = (SELECT ps.s_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l))
GROUP BY 
    ci.nation_name, ci.region_name
ORDER BY 
    ci.region_name, supplier_count DESC;
