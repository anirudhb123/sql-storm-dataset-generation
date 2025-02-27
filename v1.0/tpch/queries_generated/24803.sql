WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_price
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
        AND o.o_orderdate < DATE '2023-01-01'
),
SupplierCount AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(su.supplier_count, 0) AS supplier_count,
        ROW_NUMBER() OVER (ORDER BY p.p_retailprice DESC) AS retail_rank
    FROM 
        part p
    LEFT JOIN 
        SupplierCount su ON p.p_partkey = su.ps_partkey
)
SELECT 
    pd.p_partkey,
    pd.p_name,
    pd.p_retailprice,
    pd.supplier_count,
    CASE 
        WHEN pd.retail_rank <= 10 THEN 'Top 10'
        WHEN pd.supplier_count = 0 THEN 'No Suppliers'
        ELSE 'Other'
    END AS category,
    COUNT(DISTINCT ho.o_orderkey) AS related_orders
FROM 
    PartDetails pd
LEFT JOIN 
    HighValueOrders ho ON pd.p_partkey IN (
        SELECT DISTINCT l.l_partkey 
        FROM lineitem l 
        WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM RankedOrders ro WHERE ro.rank_price <= 5)
    )
GROUP BY 
    pd.p_partkey, pd.p_name, pd.p_retailprice, pd.supplier_count, pd.retail_rank
HAVING 
    pd.supplier_count > 0 OR category = 'Top 10'
ORDER BY 
    pd.p_retailprice DESC,
    related_orders DESC
LIMIT 50;
