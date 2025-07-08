
WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS year_rank,
        t.id
    FROM 
        aka_title t 
    WHERE 
        t.production_year IS NOT NULL
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
),
CastInfoAggregated AS (
    SELECT 
        ci.movie_id, 
        COUNT(DISTINCT ci.person_id) AS cast_count, 
        MAX(ci.nr_order) AS max_order
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    c.cast_count,
    c.max_order,
    CASE 
        WHEN c.cast_count > 10 THEN 'Large cast'
        WHEN c.cast_count IS NULL THEN 'No cast info'
        ELSE 'Small cast'
    END AS cast_size_category
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.id = mk.movie_id
LEFT JOIN 
    CastInfoAggregated c ON rm.id = c.movie_id
WHERE 
    rm.year_rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.title;
