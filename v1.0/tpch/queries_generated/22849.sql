WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank_price,
        COUNT(*) OVER (PARTITION BY p.p_type) AS total_count
    FROM 
        part p
), 
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
NationStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
), 
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_returnflag,
        l.l_linestatus,
        CASE 
            WHEN l.l_discount > 0.2 THEN 'High Discount'
            WHEN l.l_discount BETWEEN 0.1 AND 0.2 THEN 'Medium Discount'
            ELSE 'Low or No Discount'
        END AS discount_category
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
)
SELECT 
    p.p_partkey,
    p.p_name,
    ps.avg_supply_cost,
    co.total_orders,
    ns.total_suppliers,
    fl.discount_category,
    COALESCE(p.p_retailprice * fl.l_quantity, 0) AS estimated_revenue,
    CASE 
        WHEN p.p_size IS NULL THEN 'Size unknown'
        ELSE CAST(p.p_size AS VARCHAR)
    END AS part_size,
    CASE 
        WHEN ps.total_avail_qty = 0 THEN 'Out of stock'
        ELSE 'In stock'
    END AS stock_status
FROM 
    RankedParts p
LEFT JOIN 
    SupplierStats ps ON p.rank_price = 1
LEFT JOIN 
    CustomerOrders co ON ps.s_suppkey = (SELECT MIN(s2.s_suppkey) FROM SupplierStats s2 WHERE s2.total_avail_qty > 0)
LEFT JOIN 
    NationStats ns ON ns.total_suppliers = (SELECT MAX(total_suppliers) FROM NationStats)
LEFT JOIN 
    FilteredLineItems fl ON fl.l_partkey = p.p_partkey
WHERE 
    p.rank_price <= 5 AND 
    (fl.l_linestatus = 'O' OR fl.l_linestatus IS NULL)
ORDER BY 
    estimated_revenue DESC, p.p_name;
