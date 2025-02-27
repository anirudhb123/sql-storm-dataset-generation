WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_orderkey) AS total_lineitems,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS customer_order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
PartDetail AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_retailprice,
        p.p_comment,
        ps.ps_availqty
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
)
SELECT 
    n.n_name AS nation,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(os.total_price) AS total_order_value,
    AVG(ps.total_supply_value) AS avg_supplier_value,
    STRING_AGG(pd.p_name, ', ') AS part_names
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    OrderSummary os ON c.c_custkey = os.o_custkey 
LEFT JOIN 
    SupplierStats ps ON ps.s_suppkey IN (SELECT ps_suppkey FROM partsupp WHERE ps_partkey IN (SELECT p_partkey FROM PartDetail pd WHERE ps_availqty > 0))
LEFT JOIN 
    PartDetail pd ON pd.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_totalprice > 1000))
WHERE 
    n.n_name IS NOT NULL
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 10
ORDER BY 
    total_order_value DESC;
