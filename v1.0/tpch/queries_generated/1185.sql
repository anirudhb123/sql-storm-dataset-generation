WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rank
    FROM 
        orders o
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
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
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
RecentOrderDetails AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        hvc.c_name AS customer_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM 
        RankedOrders ro
    JOIN 
        lineitem l ON ro.o_orderkey = l.l_orderkey
    JOIN 
        HighValueCustomers hvc ON ro.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = hvc.c_custkey)
    WHERE 
        ro.rank = 1
    GROUP BY 
        ro.o_orderkey, ro.o_orderdate, hvc.c_name
),
FinalResult AS (
    SELECT 
        r.rr_name,
        sd.s_suppkey,
        sd.total_supply_cost,
        rc.total_spent,
        ro.o_orderkey,
        ro.total_line_value
    FROM 
        region r
    FULL OUTER JOIN SupplierSummary sd ON r.r_regionkey = (
        SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = sd.s_suppkey
    )
    FULL OUTER JOIN RecentOrderDetails ro ON sd.s_suppkey = (
        SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = (
            SELECT p.p_partkey FROM part p WHERE p.p_brand = 'Brand#23'
        )
    )
    JOIN HighValueCustomers rc ON rc.c_custkey = ro.o_orderkey
    WHERE 
        sd.total_supply_cost IS NOT NULL 
        OR ro.total_line_value IS NOT NULL
)
SELECT 
    *
FROM 
    FinalResult
ORDER BY 
    r_name ASC, sd.total_supply_cost DESC, ro.total_line_value DESC;
