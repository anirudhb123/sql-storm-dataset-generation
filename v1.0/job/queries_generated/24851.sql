WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        COUNT(DISTINCT c.person_id) AS total_cast,
        COUNT(DISTINCT CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order END) AS ordered_cast,
        COUNT(DISTINCT CASE WHEN c.note LIKE '%starring%' THEN c.person_id END) AS starring_cast,
        RANK() OVER (ORDER BY COUNT(DISTINCT c.person_id) DESC) AS cast_rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.movie_id = c.movie_id
    GROUP BY 
        m.id, m.title
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
DirectorInfo AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT CONCAT_WS(' ', n.name, '(', pt.kind, ')'), ', ') AS directors
    FROM 
        cast_info ci
    JOIN 
        aka_name n ON ci.person_id = n.person_id
    JOIN 
        role_type pt ON ci.role_id = pt.id
    WHERE 
        pt.role = 'director'
    GROUP BY 
        ci.movie_id
),
MoviesWithMissingData AS (
    SELECT 
        r.movie_id,
        r.title,
        r.total_cast,
        r.ordered_cast,
        r.starring_cast,
        COALESCE(mk.keywords, 'No Keywords') AS movie_keywords,
        COALESCE(di.directors, 'No Directors') AS movie_director
    FROM 
        RankedMovies r
    LEFT JOIN 
        MovieKeywords mk ON r.movie_id = mk.movie_id
    LEFT JOIN 
        DirectorInfo di ON r.movie_id = di.movie_id
    WHERE 
        r.total_cast < 1 OR r.starring_cast < 1
)
SELECT 
    m.title,
    m.total_cast,
    m.ordered_cast,
    m.movie_keywords,
    m.movie_director,
    MAX(m.total_cast) OVER () AS max_total_cast,
    MIN(m.total_cast) OVER () AS min_total_cast,
    SUM(m.total_cast) OVER () AS all_total_cast
FROM 
    MoviesWithMissingData m
WHERE 
    m.total_cast IS NOT NULL OR m.starring_cast IS NULL
ORDER BY 
    m.starring_cast DESC NULLS LAST,
    m.total_cast DESC;

UNION ALL

SELECT 
    'Aggregate Stats' AS title,
    MAX(r.total_cast) AS total_cast,
    AVG(r.total_cast) AS avg_total_cast,
    STRING_AGG(DISTINCT mk.keywords, ', ') AS aggregated_keywords
FROM 
    RankedMovies r
LEFT JOIN 
    MovieKeywords mk ON r.movie_id = mk.movie_id
WHERE 
    r.starring_cast > 0;
