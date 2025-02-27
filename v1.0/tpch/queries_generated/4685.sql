WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supplycost,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        SUM(CASE WHEN ps.ps_availqty < 10 THEN ps.ps_supplycost ELSE 0 END) AS low_stock_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_size,
        p.p_retailprice,
        p.p_comment
    FROM 
        part p
    WHERE 
        p.p_size > 10
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ss.s_name AS supplier_name,
    pd.p_name AS part_name,
    pd.p_retailprice,
    co.c_name AS customer_name,
    co.total_order_value,
    ss.total_parts,
    ss.avg_supplycost,
    ss.low_stock_cost
FROM 
    SupplierStats ss
FULL OUTER JOIN 
    PartDetails pd ON ss.total_parts > 0
FULL OUTER JOIN 
    CustomerOrders co ON ss.total_parts IS NOT NULL
WHERE 
    (ss.total_parts > 3 OR pd.p_retailprice > 50.00)
    AND (co.total_order_value IS NULL OR co.order_count > 2)
ORDER BY 
    ss.avg_supplycost DESC, 
    co.total_order_value DESC;
