WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_by_acctbal
    FROM 
        supplier s
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey
),
TopCustomers AS (
    SELECT 
        cust.c_custkey,
        cust.order_count,
        cust.total_spent,
        ROW_NUMBER() OVER (ORDER BY cust.total_spent DESC) AS rn
    FROM 
        CustomerOrders cust
    WHERE 
        cust.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
),
PartsInfo AS (
    SELECT 
        p.p_partkey,
        p.p_container,
        SUM(ps.ps_availqty) AS total_available,
        AVG(p.p_retailprice) AS average_price,
        STRING_AGG(CASE WHEN ps.ps_supplycost IS NULL THEN 'N/A' ELSE TO_CHAR(ps.ps_supplycost, 'FM$999999999999.00') END, '; ') AS supply_costs
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_container
)
SELECT 
    t.rn AS top_customer_rank,
    t.total_spent,
    p.p_name,
    p.container,
    p.total_available,
    p.average_price,
    s.s_name AS supplier_name,
    CASE 
        WHEN s.s_nationkey IS NULL THEN 'Unknown Region' 
        ELSE r.r_name END AS region_name
FROM 
    TopCustomers t
JOIN 
    lineitem l ON t.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = l.l_orderkey LIMIT 1)
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey AND s.rank_by_acctbal = 1
JOIN 
    Part p ON p.p_partkey = ps.ps_partkey
JOIN 
    region r ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_nationkey = s.s_nationkey)
WHERE 
    p.p_size * p.p_retailprice > (SELECT AVG(p_size * p_retailprice) FROM part)
ORDER BY 
    t.total_spent DESC, p.average_price ASC
LIMIT 100 OFFSET 50;
