WITH RegionalStats AS (
    SELECT 
        r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(p.p_retailprice) AS avg_retail_price
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
    GROUP BY 
        r_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_name AS customer_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name
),
CompositeReport AS (
    SELECT 
        rs.region_name,
        rs.supplier_count,
        rs.total_available_qty,
        rs.total_supply_cost,
        rs.avg_retail_price,
        cos.customer_name,
        cos.order_count,
        cos.total_spent,
        cos.last_order_date
    FROM 
        RegionalStats rs
    JOIN 
        CustomerOrderStats cos ON rs.region_name IN (
            SELECT r_name 
            FROM region 
            JOIN nation ON region.r_regionkey = nation.n_regionkey 
            JOIN supplier ON nation.n_nationkey = supplier.s_nationkey
            WHERE supplier.s_name LIKE '%' || UPPER(cos.customer_name) || '%'
        )
)
SELECT 
    region_name,
    supplier_count,
    total_available_qty,
    total_supply_cost,
    avg_retail_price,
    customer_name,
    order_count,
    total_spent,
    last_order_date
FROM 
    CompositeReport
ORDER BY 
    total_spent DESC, 
    supplier_count DESC;
