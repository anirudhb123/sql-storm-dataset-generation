WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL
    GROUP BY 
        c.c_custkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.r_name, 
    COALESCE(SUM(CASE WHEN rs.rank = 1 THEN rs.s_acctbal END), 0) AS top_supplier_balance,
    SUM(co.total_spent) AS customer_total_spent,
    AVG(od.revenue) AS average_order_revenue,
    COUNT(DISTINCT od.o_orderkey) AS total_orders_processed
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    RankedSuppliers rs ON rs.s_suppkey IN (
        SELECT 
            ps.ps_suppkey 
        FROM 
            partsupp ps 
        JOIN 
            part p ON ps.ps_partkey = p.p_partkey
        WHERE 
            p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    )
LEFT JOIN 
    CustomerOrders co ON co.c_custkey IN (
        SELECT 
            o.o_custkey 
        FROM 
            orders o 
        WHERE 
            o.o_orderdate > CURRENT_DATE - INTERVAL '1 YEAR'
    )
LEFT JOIN 
    OrderDetails od ON od.o_orderkey IN (
        SELECT 
            o.o_orderkey 
        FROM 
            orders o 
        WHERE 
            o.o_orderdate <= CURRENT_DATE - INTERVAL '30 DAY'
    )
GROUP BY 
    r.r_name
ORDER BY 
    top_supplier_balance DESC, 
    customer_total_spent DESC;
