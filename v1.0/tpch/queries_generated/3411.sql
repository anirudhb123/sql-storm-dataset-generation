WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT *
    FROM RankedSuppliers
    WHERE rn <= 5
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_orderdate,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Finalized'
            WHEN o.o_orderstatus = 'P' THEN 'Pending'
            ELSE 'Unknown'
        END AS order_status_desc
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_orderstatus
)
SELECT 
    ps.s_suppkey,
    ps.s_name,
    od.o_orderkey,
    od.total_revenue,
    od.order_status_desc,
    CASE 
        WHEN od.total_revenue IS NULL THEN 'No Revenue'
        WHEN od.total_revenue > 10000 THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM TopSuppliers ps
FULL OUTER JOIN OrderDetails od ON ps.s_suppkey = (SELECT ps_partkey FROM partsupp WHERE ps_availqty > 0 ORDER BY ps_supplycost DESC LIMIT 1)
WHERE ps.total_cost IS NOT NULL OR od.total_revenue IS NOT NULL
ORDER BY ps.total_cost DESC, od.total_revenue DESC
LIMIT 50;
