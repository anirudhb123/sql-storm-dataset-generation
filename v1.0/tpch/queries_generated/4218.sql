WITH SupplierCost AS (
    SELECT 
        ps.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM 
        partsupp ps
    GROUP BY 
        ps.s_suppkey
), OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS total_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), RegionSales AS (
    SELECT 
        n.n_name,
        SUM(od.total_revenue) AS region_revenue,
        COUNT(od.o_orderkey) AS order_count
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        OrderDetails od ON o.o_orderkey = od.o_orderkey
    GROUP BY 
        n.n_name
), RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sc.total_cost,
        RANK() OVER (ORDER BY sc.total_cost DESC) AS supplier_rank
    FROM 
        supplier s
    LEFT JOIN 
        SupplierCost sc ON s.s_suppkey = sc.s_suppkey
), FinalReport AS (
    SELECT 
        r.n_name AS region,
        rs.supplier_rank,
        rs.s_name AS supplier_name,
        rs.total_cost,
        rs.supplier_rank IS NULL AS no_supplier
    FROM 
        RegionSales r
    LEFT JOIN 
        RankedSuppliers rs ON r.n_name = (SELECT r_name FROM region WHERE r_regionkey = (SELECT n_regionkey FROM nation WHERE n_name = r.n_name))
)

SELECT 
    fr.region,
    fr.supplier_name,
    fr.total_cost,
    fr.supplier_rank,
    CASE 
        WHEN fr.no_supplier THEN 'No Supplier'
        ELSE 'Supplier Available'
    END AS supplier_status
FROM 
    FinalReport fr
WHERE 
    fr.supplier_rank <= 5
ORDER BY 
    fr.region, fr.total_cost DESC;
