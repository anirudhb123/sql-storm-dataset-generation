WITH SupplierPricing AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost, 
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
OrderSummary AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent, 
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
), 
PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        AVG(p.p_retailprice) AS avg_price
    FROM 
        part p
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    sp.s_name AS supplier_name, 
    ps.part_count, 
    os.c_name AS customer_name, 
    os.total_spent, 
    pd.p_name AS part_name, 
    pd.avg_price, 
    sp.total_cost
FROM 
    SupplierPricing sp
JOIN 
    OrderSummary os ON os.order_count > 5
JOIN 
    PartDetails pd ON pd.avg_price < (SELECT AVG(p_retailprice) FROM part)
WHERE 
    sp.total_cost > 100000
ORDER BY 
    sp.total_cost DESC, 
    os.total_spent DESC
LIMIT 10;
