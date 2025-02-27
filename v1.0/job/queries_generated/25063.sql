WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ARRAY_AGG(DISTINCT c.role_id) AS role_ids,
        COUNT(DISTINCT ca.person_id) AS num_cast
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info ca ON cc.subject_id = ca.id
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY num_cast DESC) AS rn
    FROM 
        RankedMovies
),
MoviesWithKeywords AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        tm.rn <= 5  -- Top 5 movies per production year
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year
)
SELECT 
    mwk.title,
    mwk.production_year,
    mwk.keywords,
    ARRAY_AGG(DISTINCT ak.name) AS aliases,
    COUNT(mci.company_id) AS num_companies
FROM 
    MoviesWithKeywords mwk
LEFT JOIN 
    movie_companies mci ON mwk.movie_id = mci.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id IN (SELECT person_id FROM cast_info WHERE movie_id = mwk.movie_id)
GROUP BY 
    mwk.title, mwk.production_year
ORDER BY 
    mwk.production_year DESC, mwk.title;
