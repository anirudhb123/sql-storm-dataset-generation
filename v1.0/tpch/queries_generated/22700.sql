WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        RANK() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
),
HighPriceSuppliers AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        s.s_acctbal, 
        s.s_name,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'Account balance unknown'
            ELSE TO_CHAR(s.s_acctbal, '999999.99') 
        END AS formatted_acctbal
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps.ps_supplycost > (SELECT AVG(ps_supplycost) FROM partsupp)
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey, 
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) FILTER (WHERE o.o_orderstatus = 'O') AS total_revenue
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
FinalResults AS (
    SELECT 
        r.r_name,
        np.n_name AS nation_name,
        COUNT(DISTINCT hss.s_suppkey) AS high_price_suppliers,
        SUM(COALESCE(cs.total_orders, 0)) AS total_orders_per_nation,
        SUM(COALESCE(cs.total_revenue, 0)) AS revenue_per_nation
    FROM 
        region r
    JOIN 
        nation np ON r.r_regionkey = np.n_regionkey
    LEFT JOIN 
        HighPriceSuppliers hss ON hss.ps_partkey IN (SELECT p_partkey FROM RankedParts WHERE price_rank <= 5)
    LEFT JOIN 
        CustomerOrderStats cs ON np.n_nationkey = cs.c_custkey
    GROUP BY 
        r.r_name, np.n_name
)
SELECT 
    r_name,
    nation_name,
    high_price_suppliers,
    total_orders_per_nation,
    revenue_per_nation
FROM 
    FinalResults
WHERE 
    (high_price_suppliers > 5 OR total_orders_per_nation > 10)
ORDER BY 
    revenue_per_nation DESC NULLS LAST;
