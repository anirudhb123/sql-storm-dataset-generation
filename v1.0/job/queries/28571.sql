WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        t.id AS movie_id
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, '; ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.cast_count,
    rm.cast_names,
    COALESCE(mk.keywords, 'No keywords available') AS movie_keywords,
    (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = rm.movie_id AND mc.company_type_id = 1) AS production_companies_count, 
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = rm.movie_id) AS info_count
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC
LIMIT 50;