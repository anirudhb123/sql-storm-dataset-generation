WITH RECURSIVE RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS sales
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        r.r_name
),
CustomerStats AS (
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
TopCustomers AS (
    SELECT 
        c.*, 
        ROW_NUMBER() OVER (ORDER BY c.total_spent DESC) AS rank
    FROM 
        CustomerStats c
    WHERE 
        c.total_spent > (SELECT AVG(total_spent) FROM CustomerStats)
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
)
SELECT 
    r.region_name,
    COALESCE(tc.c_name, 'Unknown Customer') AS customer_name,
    tc.total_spent,
    COALESCE(sd.s_name, 'Unknown Supplier') AS supplier_name,
    sd.total_cost,
    rs.sales AS regional_sales
FROM 
    RegionalSales rs
LEFT JOIN 
    TopCustomers tc ON tc.total_spent > 1000
FULL OUTER JOIN 
    SupplierDetails sd ON rs.region_name = (SELECT r_name FROM region r WHERE r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = sd.s_suppkey)))
WHERE 
    (rs.sales IS NOT NULL OR tc.order_count IS NOT NULL OR sd.part_count IS NOT NULL)
ORDER BY 
    regional_sales DESC, total_spent DESC;
