WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s_suppkey, 
        s_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS rank_sales
    FROM 
        SupplierSales
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS total_line_items,
        SUM(l.l_extendedprice) AS total_order_value,
        o.o_orderdate
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND o.o_orderdate >= DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    t.s_name,
    t.total_sales,
    t.avg_account_balance,
    od.total_order_value,
    od.total_line_items
FROM 
    TopSuppliers t
LEFT JOIN 
    OrderDetails od ON t.s_suppkey = od.o_orderkey
WHERE 
    t.rank_sales <= 5
ORDER BY 
    t.total_sales DESC, od.total_order_value DESC;
