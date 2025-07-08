
WITH OrderedData AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus, o.o_orderdate
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
RegionNations AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(n.n_nationkey) AS nation_count
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_price
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    od.o_orderkey,
    od.o_orderstatus,
    sd.s_name,
    cd.c_name,
    cd.order_count,
    cd.avg_order_price,
    r.nation_count,
    CASE 
        WHEN od.order_rank = 1 THEN 'Primary Order'
        ELSE 'Secondary Order'
    END AS order_category
FROM 
    OrderedData od
LEFT JOIN 
    SupplierDetails sd ON sd.supplier_rank <= 5
LEFT JOIN 
    CustomerOrders cd ON cd.c_custkey = (
        SELECT c.c_nationkey 
        FROM customer c 
        WHERE c.c_name IS NULL
        LIMIT 1
    )
RIGHT JOIN 
    RegionNations r ON r.nation_count IS NOT NULL
WHERE 
    od.total_revenue > (SELECT AVG(total_revenue) FROM OrderedData)
ORDER BY 
    od.total_revenue DESC, cd.order_count ASC
LIMIT 10;
