WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(ps.ps_partkey) AS part_count
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
    HAVING 
        COUNT(ps.ps_partkey) > 0
), NationalSupplierRevenue AS (
    SELECT 
        n.n_name,
        SUM(RO.total_revenue) AS national_revenue
    FROM 
        RankedOrders RO
    JOIN 
        customer c ON c.c_custkey = (
            SELECT 
                o.o_custkey FROM orders o WHERE o.o_orderkey = RO.o_orderkey
        )
    JOIN 
        supplier s ON s.s_suppkey IN (
        SELECT 
            ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (
                SELECT 
                    l.l_partkey FROM lineitem l WHERE l.l_orderkey = RO.o_orderkey
            )
        )
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    ns.n_name,
    ns.national_revenue,
    COALESCE(sd.part_count, 0) AS total_parts_supplied,
    CASE 
        WHEN ns.national_revenue > 100000 THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    NationalSupplierRevenue ns
LEFT JOIN 
    SupplierDetails sd ON ns.national_revenue = sd.s_acctbal
ORDER BY 
    ns.national_revenue DESC;
