WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
DirectorInfo AS (
    SELECT 
        c.movie_id,
        a.name AS director_name,
        COUNT(*) AS total_directors
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
    WHERE 
        c.role_id IN (SELECT id FROM role_type WHERE role = 'director')
    GROUP BY 
        c.movie_id, a.name
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    di.director_name,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_count
FROM 
    RankedMovies rm
LEFT JOIN 
    DirectorInfo di ON rm.movie_id = di.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    cast_info ci ON rm.movie_id = ci.movie_id
WHERE 
    rm.rank_per_year <= 3
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, di.director_name, mk.keywords
ORDER BY 
    rm.production_year DESC, rm.title ASC;
