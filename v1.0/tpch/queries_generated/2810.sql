WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as OrderRank
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'Unknown'
            WHEN s.s_acctbal < 1000 THEN 'Low Balance'
            ELSE 'Healthy Balance' 
        END AS Balance_Status
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
PartSummary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS Total_Avail_Qty,
        AVG(ps.ps_supplycost) AS Avg_Supply_Cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
NationRegion AS (
    SELECT 
        n.n_name AS Nation,
        r.r_name AS Region
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    ps.p_partkey,
    ps.p_name,
    ps.Total_Avail_Qty,
    ps.Avg_Supply_Cost,
    r.Region,
    COUNT(DISTINCT o.o_orderkey) AS Order_Count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS Total_Sales,
    DENSE_RANK() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS Sales_Rank
FROM 
    PartSummary ps
LEFT JOIN 
    lineitem l ON ps.p_partkey = l.l_partkey
LEFT JOIN 
    RankedOrders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    SupplierDetails s ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    NationRegion r ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA') 
WHERE 
    ps.Total_Avail_Qty > 50
    AND o.o_orderstatus IN ('O', 'F')
GROUP BY 
    ps.p_partkey, ps.p_name, ps.Total_Avail_Qty, ps.Avg_Supply_Cost, r.Region
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY 
    Sales_Rank, ps.Total_Avail_Qty DESC;
