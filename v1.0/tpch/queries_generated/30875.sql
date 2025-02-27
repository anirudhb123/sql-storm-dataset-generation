WITH RECURSIVE Order_Summaries AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) as total_spent,
        COUNT(o.o_orderkey) as order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) as rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
Top_Customers AS (
    SELECT 
        os.c_custkey, 
        os.c_name, 
        os.total_spent
    FROM Order_Summaries os
    WHERE os.rank <= 3
),
Part_Supplier_Avg AS (
    SELECT 
        ps.ps_partkey,
        AVG(ps.ps_supplycost) as avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
Part_Region AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        n.n_name as nation_name,
        r.r_name as region_name
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
), 
Customer_Orders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) as order_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) as total_sales
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey
    HAVING COUNT(o.o_orderkey) > 5
)
SELECT 
    pc.p_name,
    pr.region_name,
    tc.c_name,
    tc.total_spent,
    qa.avg_supplycost
FROM Part_Region pr
JOIN Top_Customers tc ON pr.nation_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = tc.c_custkey))
LEFT JOIN Part_Supplier_Avg qa ON pr.p_partkey = qa.ps_partkey
JOIN Customer_Orders co ON tc.c_custkey = co.c_custkey
WHERE qa.avg_supplycost IS NOT NULL
ORDER BY tc.total_spent DESC, pr.p_name ASC;
