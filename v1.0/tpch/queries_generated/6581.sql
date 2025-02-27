WITH SupplierTotalCost AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
ProductStatistics AS (
    SELECT 
        p.p_partkey,
        p.p_type,
        AVG(l.l_extendedprice) AS avg_price,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_type
)
SELECT 
    r.r_name,
    AVG(st.total_cost) AS avg_supplier_cost,
    SUM(hv.total_spent) AS total_high_value_spent,
    COUNT(ps.p_partkey) AS total_products,
    AVG(ps.avg_price) AS overall_avg_price
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierTotalCost st ON s.s_suppkey = st.s_suppkey
LEFT JOIN 
    HighValueCustomers hv ON hv.c_custkey IN (SELECT c.c_custkey FROM customer c)
LEFT JOIN 
    ProductStatistics ps ON ps.p_partkey IN (SELECT l.l_partkey FROM lineitem l)
GROUP BY 
    r.r_name;
