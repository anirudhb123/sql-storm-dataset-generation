WITH CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
PartMetrics AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice - COALESCE(s.avg_supply_cost, 0) AS profit_margin,
        p.p_brand,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM 
        part p
    LEFT JOIN 
        SupplierStats s ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s))
    WHERE 
        p.p_retailprice > 100 -- filter high retail price
),
FinalReport AS (
    SELECT 
        cs.c_name,
        ps.p_name,
        ps.profit_margin,
        cs.order_count
    FROM 
        CustomerStats cs
    JOIN 
        lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cs.c_custkey)
    JOIN 
        PartMetrics ps ON l.l_partkey = ps.p_partkey
    WHERE 
        ps.brand_rank <= 5 -- Top 5 products in each brand
)
SELECT 
    fr.c_name AS customer_name,
    fr.p_name AS product_name,
    fr.profit_margin,
    fr.order_count
FROM 
    FinalReport fr
ORDER BY 
    fr.profit_margin DESC, 
    fr.order_count DESC;
