WITH RECURSIVE CustOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
),
TotalPurchases AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
HighSpenders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        tp.total_spent
    FROM 
        customer c
    JOIN 
        TotalPurchases tp ON c.c_custkey = tp.c_custkey
    WHERE 
        tp.total_spent > (SELECT AVG(total_spent) FROM TotalPurchases)
),
PartSupplier AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_suppkey,
        s.s_name,
        ps.ps_availqty
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
SupplierStats AS (
    SELECT 
        ns.n_nationkey,
        n.n_name,
        COUNT(DISTINCT ps.ps_suppkey) AS suppliers_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        ns.n_nationkey, n.n_name
)
SELECT 
    co.c_custkey,
    co.c_name,
    co.order_rank,
    COALESCE(su.total_spent, 0) AS total_spent,
    ps.p_name,
    ss.n_name AS supplier_nation,
    ss.suppliers_count,
    ss.avg_supply_cost,
    CASE 
        WHEN o.o_orderstatus = 'F' THEN 'Completed'
        ELSE 'Pending'
    END AS order_status
FROM 
    CustOrders co
LEFT JOIN 
    HighSpenders su ON co.c_custkey = su.c_custkey
LEFT JOIN 
    lineitem li ON co.o_orderkey = li.l_orderkey
LEFT JOIN 
    PartSupplier ps ON li.l_partkey = ps.p_partkey
LEFT JOIN 
    SupplierStats ss ON ps.s_suppkey = ss.suppliers_count
ORDER BY 
    co.c_custkey, co.order_rank;
