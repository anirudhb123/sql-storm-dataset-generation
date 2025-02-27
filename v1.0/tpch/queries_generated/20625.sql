WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderstatus,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Completed'
            WHEN o.o_orderstatus = 'P' THEN 'Pending'
            ELSE 'Other' 
        END AS order_status_label
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01' 
    AND o.o_orderdate < DATE '2023-10-01'
),
LineItemsWithDiscount AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS discounted_price,
        COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS return_lines
    FROM lineitem l
    GROUP BY l.l_orderkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT fo.o_orderkey) AS order_count,
        SUM(fo.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN FilteredOrders fo ON c.c_custkey = fo.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
NationRanked AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        RANK() OVER (ORDER BY COUNT(DISTINCT s.s_suppkey) DESC) AS nation_rank
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    ns.n_name,
    cs.c_name,
    cs.order_count,
    ns.supplier_count,
    COALESCE(ls.discounted_price, 0) AS total_discounted_price,
    ns.nation_rank
FROM CustomerOrderStats cs
JOIN nation ns ON cs.c_custkey = ns.n_nationkey
LEFT JOIN LineItemsWithDiscount ls ON cs.order_count > 0 AND ls.l_orderkey IN (SELECT o.o_orderkey FROM FilteredOrders o WHERE o.o_orderkey = cs.c_custkey)
WHERE cs.total_spent > 1000
ORDER BY ns.n_name, cs.c_name;
