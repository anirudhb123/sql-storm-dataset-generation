WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
), HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal,
        DENSE_RANK() OVER (ORDER BY c.c_acctbal DESC) AS val_rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
), OrderStats AS (
    SELECT 
        o.o_orderkey, 
        COUNT(l.l_linenumber) AS total_lines, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
), FilteredParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_availqty) > 1000
)
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(c.c_acctbal) AS avg_customer_acctbal,
    MAX(os.total_amount) AS max_order_value,
    COALESCE(SUM(fp.total_avail_qty), 0) AS total_available_parts
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    RankedSuppliers s ON s.rnk <= 2
LEFT JOIN 
    HighValueCustomers c ON c.val_rank <= 5
LEFT JOIN 
    OrderStats os ON os.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')
LEFT JOIN 
    FilteredParts fp ON fp.p_partkey = ANY (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost > 50)
WHERE 
    n.n_nationkey IN (SELECT DISTINCT s_nationkey FROM supplier)
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    nation_name, region_name
FETCH FIRST 50 ROWS ONLY;
