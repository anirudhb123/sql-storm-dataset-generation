WITH recursive MovieRanked AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ci ON ci.movie_id = m.id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CompaniesWithLowCount AS (
    SELECT 
        mc.movie_id,
        COUNT(mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
    HAVING 
        COUNT(mc.company_id) < 2
),
MoviesWithReviews AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(AVG(r.rating), 0) AS average_rating
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'user_reviews')
    LEFT JOIN 
        LATERAL (SELECT CAST(SUBSTRING(mi.info FROM '(\d+(?:\.\d+)?)') AS FLOAT) AS rating 
                  FROM movie_info_idx WHERE movie_id = m.id) r ON TRUE
    GROUP BY 
        m.id
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.cast_count,
    k.keywords,
    COALESCE(c.company_count, 0) AS low_company_count,
    COALESCE(r.average_rating, 0) AS average_user_rating
FROM 
    MovieRanked m
LEFT JOIN 
    MovieKeywords k ON m.movie_id = k.movie_id
LEFT JOIN 
    CompaniesWithLowCount c ON m.movie_id = c.movie_id
LEFT JOIN 
    MoviesWithReviews r ON m.movie_id = r.movie_id
WHERE 
    m.rank <= 5 
    AND (m.production_year < 2000 OR g.reviews IS NULL OR r.average_rating > 3)
ORDER BY 
    m.production_year DESC, 
    m.cast_count DESC;

-- Check for any NULL conditions
SELECT 
    * 
FROM 
    aka_title 
WHERE 
    production_year IS NULL 
    OR title IS NULL 
    OR imdb_index IS NULL
LIMIT 10;
