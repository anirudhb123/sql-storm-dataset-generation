WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rank
    FROM 
        supplier s
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS total_line_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        os.total_order_value
    FROM 
        orders o
    JOIN 
        OrderStats os ON o.o_orderkey = os.o_orderkey
    WHERE 
        o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_availqty DESC) AS availability_rank
    FROM 
        partsupp ps
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(s.s_name, 'N/A') AS supplier_name,
    COALESCE(ha.total_order_value, 0) AS high_value_order_sum,
    sv.ps_availqty * (CASE WHEN sv.availability_rank = 1 THEN 1 ELSE 0 END) AS top_available_qty,
    R.region_name,
    DENSE_RANK() OVER (PARTITION BY R.r_name ORDER BY p.p_retailprice DESC) AS price_rank
FROM 
    part p
LEFT JOIN 
    RankedSuppliers s ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey AND ps.ps_availqty > 0 LIMIT 1)
LEFT JOIN 
    HighValueOrders ha ON ha.o_orderkey = (SELECT o.o_orderkey FROM orders o JOIN lineitem l ON o.o_orderkey = l.l_orderkey WHERE l.l_partkey = p.p_partkey ORDER BY o.o_totalprice DESC LIMIT 1)
LEFT JOIN 
    (SELECT n.n_nationkey, r.r_name as region_name 
     FROM nation n 
     JOIN region r ON n.n_regionkey = r.r_regionkey) R ON R.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = s.s_suppkey LIMIT 1)
JOIN 
    SupplierAvailability sv ON sv.ps_partkey = p.p_partkey
WHERE 
    (p.p_size BETWEEN 1 AND 20 OR p.p_retailprice IS NULL)
ORDER BY 
    p.p_partkey, 
    supplier_name DESC, 
    high_value_order_sum ASC;
