WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
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
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        r.r_name
),

OrderStats AS (
    SELECT 
        c.c_nationkey,
        COUNT(o.o_orderkey) AS orders_count,
        AVG(o.o_totalprice) AS average_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
),

SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        MAX(ps.ps_supplycost) AS max_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
)

SELECT 
    r.region_name,
    rs.total_sales,
    os.orders_count,
    os.average_order_value,
    ss.total_available_quantity,
    ss.max_supply_cost
FROM 
    RegionalSales rs
LEFT OUTER JOIN 
    OrderStats os ON os.c_nationkey = (
      SELECT n.n_nationkey
      FROM nation n
      JOIN supplier s ON n.n_nationkey = s.s_nationkey
      WHERE s.s_suppkey IN (SELECT ps.s_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_name LIKE '%Steel%'))
      LIMIT 1
    )
LEFT OUTER JOIN 
    SupplierStats ss ON ss.s_suppkey = (
      SELECT ps.ps_suppkey 
      FROM partsupp ps 
      WHERE ps.ps_availqty > 100 
      ORDER BY ps.ps_supplycost DESC 
      LIMIT 1
    )
WHERE 
    rs.total_sales IS NOT NULL
ORDER BY 
    rs.total_sales DESC;
