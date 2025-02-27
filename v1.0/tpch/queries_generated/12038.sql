SELECT
    n.n_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM
    lineitem l
