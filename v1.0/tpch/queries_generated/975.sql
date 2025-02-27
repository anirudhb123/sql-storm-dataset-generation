WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
), SupplierTotals AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(*) AS parts_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
), CustomerOrderCounts AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
) 
SELECT 
    r.r_name,
    n.n_name,
    p.p_name,
    s.s_name,
    c.c_name,
    coalesce(coc.order_count, 0) AS order_count,
    s.total_supply_cost,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY s.total_supply_cost DESC) AS rank_by_supply_cost
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    CustomerOrderCounts coc ON s.s_suppkey = (
        SELECT s2.s_suppkey 
        FROM supplier s2 
        WHERE s2.s_nationkey = n.n_nationkey 
        ORDER BY s2.s_acctbal DESC 
        LIMIT 1
    )
WHERE 
    p.p_retailprice > 100.00
    AND EXISTS (
        SELECT 1 
        FROM RankedOrders ro 
        WHERE ro.o_orderkey = (
            SELECT o.o_orderkey 
            FROM orders o 
            JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
            WHERE l.l_partkey = p.p_partkey 
            LIMIT 1
        )
        AND ro.order_rank <= 10
    )
ORDER BY 
    r.r_name, 
    rank_by_supply_cost;
