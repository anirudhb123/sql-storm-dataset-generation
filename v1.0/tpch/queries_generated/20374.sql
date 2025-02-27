WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
),
PriceSummary AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_supplycost) AS total_supply_cost, 
        AVG(ps.ps_availqty) AS avg_avail_qty
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 100.00 OR ps.ps_supplycost IS NULL
    GROUP BY 
        ps.ps_partkey
),
RecentOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        DENSE_RANK() OVER (ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus != 'F'
),
NationParts AS (
    SELECT 
        n.n_name, 
        p.p_name, 
        p.p_retailprice, 
        CASE 
            WHEN p.p_size IS NULL THEN 'Unknown Size'
            ELSE CAST(p.p_size AS varchar)
        END AS size_info
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_type LIKE '%metal%' AND s.s_acctbal IS NOT NULL
)
SELECT 
    R.s_name AS Supplier_Name,
    N.n_name AS Nation,
    SUM(RA.total_supply_cost) AS Total_Supply_Cost,
    AVG(NP.p_retailprice) AS Avg_Part_Retail_Price,
    COUNT(DISTINCT RA.o_orderkey) AS Orders_Count,
    STRING_AGG(DISTINCT NP.size_info, ', ') AS Size_Info_List
FROM 
    RankedSuppliers R
JOIN 
    PriceSummary RA ON R.s_suppkey = RA.ps_partkey
JOIN 
    RecentOrders O ON O.o_orderkey IN (
        SELECT o_orderkey FROM orders WHERE o_orderkey = O.o_orderkey
    )
JOIN 
    NationParts NP ON R.s_nationkey = NP.p_name
LEFT JOIN 
    region REG ON R.s_nationkey = REG.r_regionkey
WHERE 
    R.supplier_rank <= 5
    AND (RA.avg_avail_qty IS NOT NULL OR R.s_acctbal > 500.00)
    AND (NP.p_retailprice BETWEEN 50.00 AND 500.00 OR NP.p_retailprice IS NULL)
GROUP BY 
    R.s_name, N.n_name
HAVING 
    COUNT(RA.ps_partkey) > 1
ORDER BY 
    Total_Supply_Cost DESC, Avg_Part_Retail_Price ASC;
