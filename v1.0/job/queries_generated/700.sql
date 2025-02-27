WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COALESCE(si.info, 'No synopsis available') AS synopsis,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_order,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'synopsis')
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, si.info
),
HighCastMovies AS (
    SELECT 
        movie_id, title, synopsis, cast_count, avg_order
    FROM 
        RankedMovies
    WHERE 
        cast_count > 5
),
MoviesWithKeywords AS (
    SELECT 
        m.movie_id, 
        m.title, 
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        HighCastMovies m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.movie_id, m.title
)
SELECT 
    mwk.title,
    mwk.keywords,
    CASE 
        WHEN mwk.cast_count > 10 THEN 'Blockbuster'
        WHEN mwk.cast_count BETWEEN 6 AND 10 THEN 'Moderate Success'
        ELSE 'Indie'
    END AS success_category,
    ROW_NUMBER() OVER (ORDER BY mwk.cast_count DESC) AS movie_rank
FROM 
    MoviesWithKeywords mwk
WHERE 
    mwk.keywords IS NOT NULL
ORDER BY 
    movie_rank
LIMIT 20;
