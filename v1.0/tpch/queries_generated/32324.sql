WITH RECURSIVE OrderSummary AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(l.l_orderkey) AS item_count,
        MAX(l.l_shipdate) AS last_ship_date
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_name
), 
PartSupplier AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name,
        ps.ps_supplycost,
        (CASE 
            WHEN ps.ps_availqty IS NULL THEN 0 
            ELSE ps.ps_availqty 
        END) AS available_quantity
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_size > 10)
),
RegionSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(os.total_sales) AS total_nation_sales
    FROM 
        nation n
    JOIN 
        OrderSummary os ON n.n_nationkey = (
            SELECT DISTINCT c.c_nationkey
            FROM customer c
            WHERE c.c_name = os.c_name
        )
    GROUP BY 
        n.n_name
)
SELECT 
    r.r_name,
    COALESCE(rs.total_nation_sales, 0) AS nation_total_sales,
    p.p_name,
    p.available_quantity,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY COALESCE(rs.total_nation_sales, 0) DESC) AS rank
FROM 
    region r
LEFT JOIN 
    RegionSales rs ON r.r_name = rs.nation_name
JOIN 
    PartSupplier p ON p.available_quantity > 0
ORDER BY 
    r.r_name ASC, rank ASC;
