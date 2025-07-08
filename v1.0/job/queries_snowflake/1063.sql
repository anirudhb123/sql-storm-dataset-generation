
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
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
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    COALESCE(ac.actor_count, 0) AS actor_count,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN r.rank <= 3 THEN 'Top Ranked'
        WHEN r.rank BETWEEN 4 AND 10 THEN 'Mid Ranked'
        ELSE 'Lower Ranked'
    END AS rank_category
FROM 
    RankedMovies r
LEFT JOIN 
    ActorCounts ac ON r.movie_id = ac.movie_id
LEFT JOIN 
    MovieKeywords mk ON r.movie_id = mk.movie_id
WHERE 
    (r.production_year > 2000 AND r.rank <= 10) 
    OR (ac.actor_count IS NOT NULL AND mk.keywords IS NOT NULL)
ORDER BY 
    r.production_year DESC, 
    r.rank;
