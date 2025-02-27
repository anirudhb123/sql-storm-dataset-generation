WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS title_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(mi.info, 'No Information') AS info,
        COALESCE(kt.keyword, 'No Keywords') AS keyword
    FROM 
        title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = 1
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kt ON mk.keyword_id = kt.id
)
SELECT 
    t.production_year,
    COUNT(DISTINCT t.title) AS total_titles,
    MAX(c.actor_count) AS max_actors_per_movie,
    STRING_AGG(DISTINCT mu.title, ', ') AS movies_with_keywords,
    COUNT(DISTINCT R.title_rank) AS unique_title_ranks
FROM 
    RankedTitles R
LEFT JOIN 
    ActorCounts c ON R.title = c.movie_id
LEFT JOIN 
    MovieInfo mu ON R.title = mu.title
GROUP BY 
    t.production_year
HAVING 
    COUNT(DISTINCT t.title) > 10
ORDER BY 
    t.production_year DESC;
