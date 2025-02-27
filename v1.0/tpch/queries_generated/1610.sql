WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.total_sales,
        s.order_count,
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        SupplierSales s
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.total_sales,
        rs.order_count
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 10
),
SupplyDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        COALESCE(SUM(l.l_quantity), 0) AS total_quantity_sold
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
)

SELECT 
    ts.s_name,
    sd.p_name,
    sd.ps_availqty,
    sd.ps_supplycost,
    sd.total_quantity_sold,
    (sd.ps_supplycost * sd.total_quantity_sold) AS total_cost,
    (sd.ps_supplycost * sd.total_quantity_sold) - ts.total_sales AS margin
FROM 
    TopSuppliers ts
JOIN 
    SupplyDetails sd ON ts.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = sd.p_partkey LIMIT 1)
WHERE 
    sd.total_quantity_sold > 0
ORDER BY 
    ts.total_sales DESC, sd.total_quantity_sold DESC;
