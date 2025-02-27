WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        COUNT(DISTINCT cm.company_id) AS company_count
    FROM 
        cast_info c
    LEFT JOIN 
        movie_companies cm ON c.movie_id = cm.movie_id
    GROUP BY 
        c.movie_id
),
FilteredMovies AS (
    SELECT 
        m.title,
        m.production_year,
        am.actor_count,
        am.company_count
    FROM 
        RankedTitles m
    JOIN 
        ActorMovies am ON m.title_id = am.movie_id
    WHERE 
        am.actor_count > 5 AND am.company_count > 2
)
SELECT 
    f.title,
    f.production_year,
    f.actor_count,
    f.company_count,
    COALESCE(k.keyword, 'No Keywords') AS keyword
FROM 
    FilteredMovies f
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = f.title_id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
ORDER BY 
    f.production_year DESC, f.title;
