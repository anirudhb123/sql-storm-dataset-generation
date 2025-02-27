WITH RankedTitles AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) as rank
    FROM 
        aka_title at
    WHERE 
        at.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
MovieActors AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
MoviesWithKeyword AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    COALESCE(ma.actor_count, 0) AS actor_count,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN ma.actor_count IS NULL THEN 'No cast information'
        WHEN ma.actor_count = 0 THEN 'No actors'
        ELSE 'Has actors'
    END AS actor_info
FROM 
    RankedTitles rt
LEFT JOIN 
    MovieActors ma ON rt.id = ma.movie_id
LEFT JOIN 
    MoviesWithKeyword mk ON rt.id = mk.movie_id
WHERE 
    rt.rank <= 5
ORDER BY 
    rt.production_year DESC, 
    rt.title;
