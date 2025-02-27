WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COUNT(DISTINCT c.person_id) AS total_cast,
        RANK() OVER (ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_total_cast
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title
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
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, '; ') AS info_details
    FROM 
        movie_info mi
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Summary')
    GROUP BY 
        mi.movie_id
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(mi.info_details, 'No summary available') AS summary,
    m.total_cast,
    rank_total_cast
FROM 
    RankedMovies m
LEFT JOIN 
    MovieKeywords mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    MovieInfo mi ON m.movie_id = mi.movie_id
WHERE 
    m.total_cast > 5
    AND m.production_year >= 2000
ORDER BY 
    rank_total_cast, m.title;
