WITH RECURSIVE nation_supply AS (
    SELECT n.n_nationkey, n.n_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_nationkey, n.n_name
),
region_summary AS (
    SELECT r.r_regionkey, r.r_name, SUM(n.total_supplycost) AS region_supplycost
    FROM region r
    JOIN nation_supply n ON n.n_nationkey IN (
        SELECT n_nationkey 
        FROM nation 
        WHERE n_regionkey = r.r_regionkey
    )
    GROUP BY r.r_regionkey, r.r_name
),
top_regions AS (
    SELECT r.r_name, r.region_supplycost, RANK() OVER (ORDER BY r.region_supplycost DESC) as region_rank
    FROM region_summary r
)
SELECT r.r_name, r.region_supplycost
FROM top_regions r
WHERE r.region_rank <= 5
ORDER BY r.region_supplycost DESC;
