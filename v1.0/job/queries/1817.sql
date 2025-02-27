
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        DENSE_RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast,
        t.id AS movie_id
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieKeywords AS (
    SELECT 
        t.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
)
SELECT 
    m.title,
    m.production_year,
    m.total_cast, 
    COALESCE(k.keywords, 'No keywords') AS keywords,
    (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = m.movie_id AND mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Distributor')) AS distributor_count
FROM 
    RankedMovies m
LEFT JOIN 
    MovieKeywords k ON m.movie_id = k.movie_id
WHERE 
    m.rank_by_cast = 1 OR 
    m.production_year > 2000
ORDER BY 
    m.production_year DESC, m.total_cast DESC;
