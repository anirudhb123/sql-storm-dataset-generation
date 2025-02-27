WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        s.s_nationkey,
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        o.o_orderdate,
        o.o_orderstatus
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
PartSupplier AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_availability,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    p.p_name,
    SUM(os.total_sales) AS total_order_sales,
    COUNT(DISTINCT os.o_orderkey) AS order_count,
    STRING_AGG(DISTINCT sd.nation_name, ', ') AS supplier_nations,
    MAX(ps.total_availability) AS max_availability,
    MIN(ps.avg_supply_cost) AS min_supply_cost,
    CASE 
        WHEN SUM(os.total_sales) > 10000 THEN 'High'
        WHEN SUM(os.total_sales) >= 5000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM 
    part p
LEFT JOIN 
    PartSupplier ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    OrderSummary os ON ps.ps_suppkey = os.o_orderkey
LEFT JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
WHERE 
    p.p_container IS NOT NULL 
    AND (p.p_size BETWEEN 1 AND 30 OR p.p_retailprice < 50)
GROUP BY 
    p.p_name
HAVING 
    COUNT(sd.nation_name) > 1
ORDER BY 
    total_order_sales DESC;