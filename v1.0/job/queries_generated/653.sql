WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS yearly_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(ci.person_id) AS actor_count,
        MAX(ci.nr_order) AS max_order
    FROM 
        cast_info ci
    JOIN 
        complete_cast cc ON ci.movie_id = cc.movie_id
    GROUP BY 
        c.movie_id
),
KeywordDetails AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cd.actor_count, 0) AS actor_count,
    COALESCE(kd.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN rm.yearly_rank = 1 THEN 'Latest Movie'
        ELSE 'Previous Release'
    END AS release_status,
    (CASE 
        WHEN cd.max_order IS NULL THEN 'No actors'
        ELSE cd.max_order::text || ' actors featured'
    END) AS actor_summary
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    KeywordDetails kd ON rm.movie_id = kd.movie_id
WHERE 
    rm.production_year BETWEEN 2000 AND 2023
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
