WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
), 
PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        STRING_AGG(p.p_comment, '; ') AS combined_comments
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
), 
HighValueSuppliers AS (
    SELECT 
        rs.s_name
    FROM RankedSuppliers rs
    WHERE rs.rank <= 5
)
SELECT 
    pd.p_partkey, 
    pd.p_name, 
    pd.total_avail_qty, 
    pd.total_supply_cost, 
    pd.combined_comments, 
    hvs.s_name
FROM PartDetails pd
CROSS JOIN HighValueSuppliers hvs
WHERE pd.total_avail_qty > 100
ORDER BY pd.total_supply_cost DESC, pd.p_partkey;
