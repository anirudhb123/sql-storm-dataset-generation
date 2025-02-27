WITH SupplierCosts AS (
    SELECT 
        ps.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        COALESCE(SUM(l.l_extendedprice), 0) AS total_sales
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
RankedSuppliers AS (
    SELECT 
        sd.*,
        RANK() OVER (PARTITION BY sd.nation_name ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        SupplierDetails sd
)
SELECT 
    co.c_custkey,
    co.order_count,
    co.total_spent,
    rs.s_suppkey,
    rs.s_name,
    rs.nation_name,
    rs.total_sales,
    CASE 
        WHEN rs.total_sales > 50000 THEN 'High Value'
        ELSE 'Regular'
    END AS supplier_value_category
FROM 
    CustomerOrders co
FULL OUTER JOIN 
    RankedSuppliers rs ON co.order_count = rs.sales_rank
WHERE 
    co.total_spent IS NOT NULL OR rs.total_sales IS NOT NULL
ORDER BY 
    co.total_spent DESC NULLS LAST, rs.total_sales ASC;
