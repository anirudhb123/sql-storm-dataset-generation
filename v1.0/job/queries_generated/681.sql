WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        m.movie_id,
        COALESCE(c.name, 'Unknown') AS company_name,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        MAX(CASE WHEN mk.keyword IS NOT NULL THEN mk.keyword ELSE 'No Keyword' END) AS keyword
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON mc.movie_id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        movie_keyword mk ON mc.movie_id = mk.movie_id
    JOIN 
        RankedMovies rm ON mc.movie_id = rm.movie_id
    GROUP BY 
        m.movie_id, company_name
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    md.company_name,
    md.cast_count,
    md.actors,
    md.keyword
FROM 
    RankedMovies m
JOIN 
    MovieDetails md ON m.movie_id = md.movie_id
WHERE 
    md.cast_count > 5
    AND m.rank_per_year <= 10
ORDER BY 
    m.production_year DESC, 
    md.cast_count DESC;
