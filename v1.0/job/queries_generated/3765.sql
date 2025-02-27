WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.title, t.production_year
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
    m.cast_count,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    (SELECT MAX(ci.nr_order) FROM cast_info ci WHERE ci.movie_id = m.movie_id AND ci.note IS NOT NULL) AS max_order,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = m.movie_id AND mi.note IS NOT NULL) AS info_count
FROM 
    RankedMovies m
LEFT JOIN 
    MovieKeywords mk ON m.title = mk.movie_id
WHERE 
    m.rank <= 5 
    AND (m.production_year IS NOT NULL OR m.production_year > 2000)
ORDER BY 
    m.production_year DESC, m.cast_count DESC;
