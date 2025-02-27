WITH SupplierCosts AS (
    SELECT 
        s.s_suppkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_availqty > 0
    GROUP BY 
        s.s_suppkey
),

OrderDetails AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_linenumber) AS total_lines,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
      AND 
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),

TopNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(od.total_sales) AS total_sales_by_nation
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        OrderDetails od ON o.o_orderkey = od.o_orderkey
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        SUM(od.total_sales) IS NOT NULL
)

SELECT 
    r.r_name AS region_name,
    tn.n_name AS nation_name,
    COALESCE(tn.total_sales_by_nation, 0) AS total_sales,
    COUNT(DISTINCT sc.s_suppkey) AS total_suppliers,
    AVG(sc.total_supply_cost) AS avg_supply_cost
FROM 
    region r
LEFT JOIN 
    nation tn ON r.r_regionkey = tn.n_regionkey
LEFT JOIN 
    SupplierCosts sc ON sc.s_suppkey IN (
        SELECT 
            ps.ps_suppkey 
        FROM 
            partsupp ps 
        JOIN 
            part p ON ps.ps_partkey = p.p_partkey 
        WHERE 
            p.p_brand = 'Brand#23' 
          AND 
            p.p_type LIKE 'Type%')
GROUP BY 
    r.r_name, tn.n_name
ORDER BY 
    total_sales DESC, region_name ASC
LIMIT 10;
