WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        DENSE_RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ' ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    a.name AS actor_name,
    COALESCE(rm.title, 'Unknown Title') AS movie_title,
    COALESCE(rm.production_year, 0) AS production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN rm.rank IS NULL THEN 'Non-Featured'
        ELSE 'Featured'
    END AS movie_feature_status
FROM 
    aka_name a
LEFT JOIN 
    cast_info ci ON a.person_id = ci.person_id
LEFT JOIN 
    RankedMovies rm ON ci.movie_id = rm.movie_id
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = rm.movie_id
WHERE 
    a.name IS NOT NULL
    AND (rm.production_year IS NULL OR rm.production_year >= 2000 OR rm.production_year IS NULL)
ORDER BY 
    a.name, rm.production_year DESC NULLS LAST;
