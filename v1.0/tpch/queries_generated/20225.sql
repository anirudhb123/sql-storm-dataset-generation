WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
), PartSuppliers AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), DiscountedRevenue AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS adjusted_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
), RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS revenue_rank
    FROM 
        orders o
), RegionStats AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(s.s_acctbal) AS total_supplier_balance
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
)

SELECT 
    c.c_name,
    co.total_spent,
    ps.total_available,
    dr.adjusted_revenue,
    r.revenue_rank,
    rs.nation_count,
    rs.total_supplier_balance
FROM 
    CustomerOrders co
JOIN 
    PartSuppliers ps ON ps.ps_partkey IN (
        SELECT l.l_partkey
        FROM lineitem l
        WHERE l.l_orderkey IN (
            SELECT o.o_orderkey 
            FROM orders o
            WHERE o.o_orderdate < '2023-01-01' AND o.o_orderstatus = 'F'
        )
    )
JOIN 
    DiscountedRevenue dr ON dr.l_orderkey = ANY (
        SELECT o.o_orderkey 
        FROM RankedOrders o
        WHERE o.revenue_rank <= 10
    )
JOIN 
    RegionStats rs ON EXISTS (
        SELECT 1 
        FROM supplier s
        WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > co.total_spent
    )
WHERE 
    co.order_count > 5 AND 
    (ps.total_available IS NULL OR ps.total_available > 100)
ORDER BY 
    co.total_spent DESC, 
    rs.total_supplier_balance DESC;
