WITH RankedSales AS (
    SELECT 
        l_orderkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY l_orderkey ORDER BY SUM(l_extendedprice * (1 - l_discount)) DESC) AS revenue_rank
    FROM 
        lineitem 
    GROUP BY 
        l_orderkey
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (ORDER BY s.s_acctbal DESC) AS account_rank
    FROM 
        supplier s 
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_acctbal IS NOT NULL)
),
PartSupplier AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        (ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        part p 
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice IS NOT NULL AND p.p_retailprice > 0
),
OrdersSuppliers AS (
    SELECT 
        o.o_orderkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        MAX(RS.total_revenue) AS max_revenue
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    LEFT JOIN 
        PartSupplier ps ON l.l_partkey = ps.p_partkey
    LEFT JOIN 
        RankedSales RS ON o.o_orderkey = RS.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    R.n_name AS nation_name,
    COUNT(DISTINCT os.o_orderkey) AS order_count,
    AVG(os.max_revenue) AS avg_revenue,
    COALESCE(SD.s_name, 'No Supplier') AS top_supplier
FROM 
    nation R
LEFT JOIN 
    supplier S ON R.n_nationkey = S.s_nationkey
LEFT JOIN 
    OrdersSuppliers os ON S.s_suppkey = os.supplier_count
LEFT JOIN 
    SupplierDetails SD ON S.s_suppkey = SD.s_suppkey AND SD.account_rank = 1
WHERE 
    (R.r_name LIKE '%land%' OR R.r_comment IS NULL)
GROUP BY 
    R.n_name, SD.s_name
HAVING 
    COUNT(DISTINCT os.o_orderkey) > 5
ORDER BY 
    nation_name DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
