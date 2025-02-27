WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS status_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1995-01-01' AND o.o_orderdate < '1996-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment,
        COALESCE(d.sales_total, 0) AS total_sales
    FROM 
        supplier s
    LEFT JOIN (
        SELECT 
            ps.ps_suppkey,
            SUM(l.l_extendedprice * (1 - l.l_discount)) AS sales_total
        FROM 
            partsupp ps
        JOIN 
            lineitem l ON ps.ps_partkey = l.l_partkey
        GROUP BY 
            ps.ps_suppkey
    ) d ON s.s_suppkey = d.ps_suppkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS value_rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer WHERE c_acctbal IS NOT NULL)
),
PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        (SELECT COUNT(*) FROM partsupp ps2 WHERE ps2.ps_partkey = p.p_partkey) AS num_suppliers
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > 100 AND p.p_size IN (10, 20, 30)
)
SELECT 
    r.o_orderkey,
    r.o_orderstatus,
    r.o_totalprice,
    CONCAT('Total Sales: ', CAST(sd.total_sales AS VARCHAR(50))) AS sales_info,
    c.c_name AS high_value_customer,
    pi.p_name AS part_name,
    pi.num_suppliers
FROM 
    RankedOrders r
JOIN 
    SupplierDetails sd ON r.o_orderkey = sd.s_suppkey
LEFT JOIN 
    HighValueCustomers c ON c.value_rank <= 10
JOIN 
    PartSupplierInfo pi ON pi.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sd.s_suppkey LIMIT 1)
WHERE 
    r.status_rank <= 5 
    AND pi.num_suppliers IS NOT NULL
ORDER BY 
    r.o_totalprice DESC, 
    sd.total_sales ASC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
