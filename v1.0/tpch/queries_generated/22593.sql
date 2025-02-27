WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F')
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 1000
),
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(*) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 500
    GROUP BY 
        ps.ps_partkey
),
FilteredNation AS (
    SELECT 
        n.n_nationkey,
        n.n_name
    FROM 
        nation n
    WHERE 
        n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE 'Asia%')
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    CASE 
        WHEN ps.total_supply_cost IS NULL THEN 'No Supply Cost'
        ELSE CONCAT('Total Supply Cost: ', CAST(ps.total_supply_cost AS VARCHAR))
    END AS supply_cost_info,
    COALESCE(c.total_orders, 0) AS total_orders_by_customer,
    COALESCE(c.total_spent, 0) AS total_spent_by_customer,
    fn.n_name AS nation_name
FROM 
    part p
LEFT JOIN 
    PartSupplierDetails ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    CustomerSummary c ON c.c_custkey = (SELECT 
                                             o.o_custkey
                                         FROM 
                                             RankedOrders o
                                         WHERE 
                                             o.o_orderkey = (SELECT MAX(o2.o_orderkey) FROM orders o2)
                                         LIMIT 1)
LEFT JOIN 
    FilteredNation fn ON EXISTS (SELECT 1 FROM supplier s WHERE s.s_nationkey = fn.n_nationkey AND s.s_acctbal > 300)
WHERE 
    (p.p_size BETWEEN 1 AND 15 OR p.p_retailprice IS NULL)
ORDER BY 
    p.p_partkey, total_orders_by_customer DESC, total_spent_by_customer DESC;
