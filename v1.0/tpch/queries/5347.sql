WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_by_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        cust.c_custkey, 
        cust.c_name, 
        cust.order_count, 
        cust.total_spent,
        RANK() OVER (ORDER BY cust.total_spent DESC) AS rank_by_spending
    FROM 
        CustomerOrders cust
)
SELECT 
    r.r_name AS region_name, 
    tc.c_name AS top_customer, 
    tc.total_spent, 
    rp.p_brand, 
    rp.total_supply_cost
FROM 
    TopCustomers tc
JOIN 
    nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = tc.c_custkey)
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    RankedParts rp ON rp.rank_by_cost = 1
WHERE 
    tc.rank_by_spending <= 10
ORDER BY 
    r.r_name, tc.total_spent DESC;