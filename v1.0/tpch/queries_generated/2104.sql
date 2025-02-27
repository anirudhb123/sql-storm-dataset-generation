WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), LineitemDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(l.l_linenumber) AS lineitem_count
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
), HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name
    FROM 
        CustomerOrders c
    WHERE 
        c.total_spent > (
            SELECT 
                AVG(total_spent) 
            FROM 
                CustomerOrders
        )
)
SELECT 
    s.s_name,
    ss.total_available,
    ss.avg_supply_cost,
    hs.c_name AS high_value_customer,
    COALESCE(ld.net_revenue, 0) AS lineitem_revenue,
    ld.lineitem_count
FROM 
    SupplierStats ss
LEFT JOIN 
    lineitemdetails ld ON ss.s_suppkey = ld.l_orderkey
JOIN 
    HighValueCustomers hs ON ss.unique_parts > 5
ORDER BY 
    ss.total_available DESC, ss.avg_supply_cost ASC;
