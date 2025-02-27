WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL
        AND a.name IS NOT NULL 
    GROUP BY 
        t.id, t.title, t.production_year
), MoviesWithKeywords AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast,
        rm.actors,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, rm.total_cast, rm.actors
)
SELECT 
    mwk.movie_id,
    mwk.title,
    mwk.production_year,
    mwk.total_cast,
    mwk.actors,
    mwk.keyword_count,
    ct.kind AS company_type
FROM 
    MoviesWithKeywords mwk
LEFT JOIN 
    movie_companies mc ON mwk.movie_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    mwk.keyword_count > 5
ORDER BY 
    mwk.production_year ASC, mwk.total_cast DESC;
