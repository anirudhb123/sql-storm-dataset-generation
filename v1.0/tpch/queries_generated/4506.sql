WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_availqty) AS total_available_quantity,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.total_available_quantity,
        s.unique_parts_supplied,
        RANK() OVER (ORDER BY s.total_available_quantity DESC) AS supplier_rank
    FROM 
        SupplierStats s
    WHERE 
        s.unique_parts_supplied > 5
),
FinalReport AS (
    SELECT 
        od.o_orderkey,
        od.o_orderdate,
        ts.s_name AS top_supplier_name,
        od.total_revenue,
        DENSE_RANK() OVER (PARTITION BY od.o_orderdate ORDER BY od.total_revenue DESC) AS revenue_rank
    FROM 
        OrderDetails od
    LEFT JOIN 
        TopSuppliers ts ON od.o_orderkey IN (
            SELECT 
                l.l_orderkey
            FROM 
                lineitem l
            JOIN 
                partsupp ps ON l.l_partkey = ps.ps_partkey
            WHERE 
                ps.ps_availqty > 0
        )
)
SELECT 
    fr.o_orderkey,
    fr.o_orderdate,
    COALESCE(fr.top_supplier_name, 'No Supplier') AS supplier_name,
    fr.total_revenue,
    fr.revenue_rank
FROM 
    FinalReport fr
WHERE 
    fr.total_revenue > 10000
ORDER BY 
    fr.o_orderdate DESC, fr.total_revenue DESC;
