WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        c.movie_id,
        ak.name AS actor_name,
        RANK() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    a.actor_name,
    CASE 
        WHEN a.actor_rank = 1 THEN 'Lead Actor'
        WHEN a.actor_rank <= 3 THEN 'Supporting Actor'
        ELSE 'Other'
    END AS actor_role,
    COALESCE(ct.kind, 'Unknown') AS company_type,
    COUNT(DISTINCT mk.keyword) AS keyword_count
FROM 
    RankedMovies m
LEFT JOIN 
    ActorMovies a ON m.movie_id = a.movie_id
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
WHERE 
    m.year_rank <= 10
GROUP BY 
    m.movie_id, m.title, m.production_year, a.actor_name, a.actor_rank, ct.kind
ORDER BY 
    m.production_year DESC, a.actor_rank;
