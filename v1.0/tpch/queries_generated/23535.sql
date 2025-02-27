WITH RECURSIVE customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
),
parts_with_availability AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(SUM(ps.ps_availqty), 0) AS total_availqty
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
),
ranked_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier GROUP BY s_nationkey)
),
latest_order AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_status_rank
    FROM 
        orders o
),
national_part_suppliers AS (
    SELECT 
        n.n_name,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        n.n_name, p.p_name
)
SELECT 
    c.c_name,
    o.o_orderkey,
    COALESCE(lp.o_orderstatus, 'UNKNOWN') AS order_status,
    pp.p_name,
    pp.total_availqty,
    pp.p_retailprice,
    ns.n_name,
    ns.total_supply_cost
FROM 
    customer_orders co
LEFT JOIN 
    latest_order lp ON co.o_orderkey = lp.o_orderkey AND lp.order_status_rank = 1
JOIN 
    parts_with_availability pp ON pp.total_availqty > 0
LEFT JOIN 
    national_part_suppliers ns ON ns.p_name = pp.p_name
WHERE 
    co.rank = 1
    AND pp.p_retailprice * pp.total_availqty < 
        (SELECT AVG(pp2.p_retailprice * pp2.total_availqty) 
         FROM parts_with_availability pp2)
ORDER BY 
    c.c_name ASC, pp.p_name ASC;
