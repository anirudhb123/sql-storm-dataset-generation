WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_supplycost,
        RANK() OVER (PARTITION BY CASE WHEN s.s_acctbal IS NULL THEN 'Unknown' ELSE 'Known' END ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
), HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS row_num
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_acctbal > (
            SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_acctbal IS NOT NULL
        )
), OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        l.l_discount,
        l.l_tax,
        (l.l_extendedprice * (1 - l.l_discount) + l.l_tax) AS total_line_price,
        o.o_orderdate,
        COALESCE(o.o_orderstatus, 'UNKNOWN') AS order_status
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2021-01-01' AND '2023-12-31'
)
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    SUM(os.total_line_price) AS total_sales,
    COUNT(DISTINCT hv.c_custkey) AS high_value_customers,
    MAX(s.total_supplycost) AS max_supply_cost,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ': ', s.total_supplycost) ORDER BY s.total_supplycost DESC) AS supplier_details
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    orders o ON o.o_custkey IN (SELECT c.c_custkey FROM HighValueCustomers hv JOIN customer c ON hv.c_custkey = c.c_custkey)
JOIN 
    OrderSummary os ON os.o_orderkey = o.o_orderkey
LEFT JOIN 
    RankedSuppliers s ON s.s_suppkey IN (SELECT l.l_suppkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey)
WHERE 
    n.n_nationkey IS NOT NULL AND r.r_name IS NOT NULL
GROUP BY 
    n.n_name, r.r_name
HAVING 
    COUNT(DISTINCT os.o_orderkey) > 10 OR MAX(s.total_supplycost) IS NULL
ORDER BY 
    total_sales DESC, high_value_customers DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
