WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           DENSE_RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supply_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, n.n_name, r.r_name, rs.total_supply_cost
    FROM RankedSuppliers rs
    JOIN supplier s ON rs.s_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE rs.supply_rank <= 5
),
AnnualOrderStats AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice) - SUM(l.l_discount) AS net_revenue,
           EXTRACT(YEAR FROM o.o_orderdate) AS order_year
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT ts.s_name, ts.n_name as nation, ts.r_name as region, 
       aos.order_year, AVG(aos.net_revenue) AS avg_net_revenue
FROM TopSuppliers ts
JOIN AnnualOrderStats aos ON ts.s_suppkey = (SELECT ps.ps_suppkey 
                                             FROM partsupp ps 
                                             JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
                                             WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o 
                                                                    WHERE EXTRACT(YEAR FROM o.o_orderdate) = aos.order_year))
GROUP BY ts.s_name, ts.n_name, ts.r_name, aos.order_year
ORDER BY ts.r_name, aos.order_year;
