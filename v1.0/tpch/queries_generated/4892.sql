WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_sales,
        COUNT(l.l_orderkey) AS line_count
    FROM 
        orders o 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate > '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_totalprice
), 
PartSupplier AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT ps.ps_suppkey) AS num_suppliers
    FROM 
        part p 
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS num_customers,
    SUM(os.net_sales) AS total_sales,
    AVG(ss.total_cost) AS avg_supplier_cost,
    MAX(ps.num_suppliers) AS max_part_suppliers
FROM 
    region r 
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    OrderDetails os ON c.c_custkey = os.o_orderkey
LEFT JOIN 
    SupplierStats ss ON ss.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM PartSupplier p WHERE p.num_suppliers > 3 LIMIT 1))
LEFT JOIN 
    PartSupplier ps ON ps.p_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_retailprice > 500.00)
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_name
ORDER BY 
    total_sales DESC;
