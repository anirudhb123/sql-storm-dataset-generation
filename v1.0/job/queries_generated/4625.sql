WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM
        aka_title t
    WHERE
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
BudgetedMovies AS (
    SELECT
        m.id AS movie_id,
        COALESCE(SUM(mk.budget), 0) AS total_budget
    FROM
        title m
    LEFT JOIN
        movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget')
    LEFT JOIN
        movie_info_idx mk ON mi.id = mk.movie_info_id
    GROUP BY
        m.id
),
ActorMovies AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM
        cast_info c
    GROUP BY
        c.movie_id
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    b.total_budget,
    a.actor_count,
    CASE 
        WHEN b.total_budget > 100000000 THEN 'High Budget'
        WHEN b.total_budget > 50000000 THEN 'Medium Budget'
        ELSE 'Low Budget'
    END AS budget_category,
    COALESCE(a.actor_count, 0) AS actor_count,
    (b.total_budget / NULLIF(a.actor_count, 0)) AS budget_per_actor
FROM 
    RankedMovies r
LEFT JOIN 
    BudgetedMovies b ON r.movie_id = b.movie_id
LEFT JOIN 
    ActorMovies a ON r.movie_id = a.movie_id
WHERE 
    r.rank <= 5
ORDER BY 
    r.production_year DESC, r.title ASC;
