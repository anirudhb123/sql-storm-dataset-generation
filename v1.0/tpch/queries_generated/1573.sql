WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem li ON li.l_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s_suppkey, 
        s_name, 
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SupplierSales
),
CustomerOrders AS (
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
NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_regionkey,
        r.r_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    n.r_name AS region_name,
    ns.n_name AS nation_name,
    ts.s_name AS supplier_name,
    co.c_name AS customer_name,
    co.order_count,
    co.total_spent,
    ts.total_sales
FROM 
    TopSuppliers ts
JOIN 
    partsupp ps ON ts.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem li ON li.l_partkey = p.p_partkey
JOIN 
    orders o ON o.o_orderkey = li.l_orderkey
JOIN 
    customer co ON co.c_custkey = o.o_custkey
JOIN 
    nation n ON n.n_nationkey = co.c_nationkey
JOIN 
    NationRegion nr ON n.n_nationkey = nr.n_nationkey
WHERE 
    co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
    AND ts.sales_rank <= 10
ORDER BY 
    region_name, nation_name, total_sales DESC;
