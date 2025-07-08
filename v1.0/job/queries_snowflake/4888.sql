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
TopRatedMovies AS (
    SELECT 
        ti.movie_id,
        COUNT(*) AS total_actors
    FROM 
        cast_info ci
    JOIN 
        aka_title ti ON ci.movie_id = ti.movie_id
    GROUP BY 
        ti.movie_id
    HAVING 
        COUNT(*) > 5
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(ki.keyword, 'No Keyword') AS keyword,
        CASE 
            WHEN m.production_year < 2000 THEN 'Classic'
            ELSE 'Modern'
        END AS era
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
)
SELECT 
    rd.title,
    rd.production_year,
    md.keyword,
    COUNT(ci.id) AS actor_count,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS confirmed_actors
FROM 
    RankedTitles rd
JOIN 
    TopRatedMovies trm ON rd.title_id = trm.movie_id
JOIN 
    MovieDetails md ON trm.movie_id = md.movie_id
LEFT JOIN 
    cast_info ci ON md.movie_id = ci.movie_id
WHERE 
    rd.title_rank <= 3
GROUP BY 
    rd.title, 
    rd.production_year,
    md.keyword
HAVING 
    COUNT(ci.id) > 2
ORDER BY 
    rd.production_year DESC, 
    actor_count DESC;
