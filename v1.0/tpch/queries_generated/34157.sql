WITH RECURSIVE SupplyChain AS (
    SELECT 
        ps_partkey, 
        ps_suppkey, 
        ps_availqty, 
        ps_supplycost, 
        1 AS level
    FROM 
        partsupp
    WHERE 
        ps_availqty > 0
    
    UNION ALL
    
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        ps.ps_availqty, 
        ps.ps_supplycost, 
        sc.level + 1
    FROM 
        partsupp ps
    JOIN 
        SupplyChain sc ON ps.ps_suppkey = sc.ps_suppkey
    WHERE 
        sc.level < 5
),
AggregateSupply AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(sc.ps_availqty) AS total_avail_qty,
        SUM(sc.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT sc.ps_suppkey) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        SupplyChain sc ON p.p_partkey = sc.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' 
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        ROW_NUMBER() OVER (ORDER BY co.total_spent DESC) AS rank
    FROM 
        customer c
    JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
)
SELECT 
    rc.r_name,
    COALESCE(SUM(asupply.total_avail_qty), 0) AS total_available_quantity,
    AVG(asupply.total_supply_cost) AS average_supply_cost,
    tc.c_name AS top_customer_name,
    tc.rank
FROM 
    region rc
LEFT JOIN 
    nation n ON rc.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    AggregateSupply asupply ON s.s_suppkey = asupply.ps_suppkey
LEFT JOIN 
    TopCustomers tc ON tc.c_custkey = s.s_suppkey
GROUP BY 
    rc.r_name, tc.c_name, tc.rank
HAVING 
    SUM(asupply.total_avail_qty) IS NOT NULL
ORDER BY 
    rc.r_name, rank DESC;
