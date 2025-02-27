WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F')
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL 
        AND o.o_orderdate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        COUNT(DISTINCT ps.ps_partkey) > 10
),
PartSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATEADD(MONTH, -3, GETDATE())
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    R.o_orderkey,
    R.o_orderdate,
    R.o_totalprice,
    COALESCE(H.c_name, 'Unknown') AS high_value_customer,
    COALESCE(S.s_name, 'No Supplier') AS supplier_name,
    P.p_name AS part_name,
    P.total_sales,
    S.part_count AS supplier_part_count
FROM 
    RankedOrders R
LEFT JOIN 
    HighValueCustomers H ON R.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = H.c_custkey)
LEFT JOIN 
    SupplierDetails S ON S.part_count >= 5
LEFT JOIN 
    PartSales P ON P.total_sales IS NOT NULL
WHERE 
    R.rnk = 1 AND 
    (R.o_totalprice IS NOT NULL OR R.o_orderstatus IS NULL)
ORDER BY 
    R.o_orderdate DESC, P.total_sales DESC;
