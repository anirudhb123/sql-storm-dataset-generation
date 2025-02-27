WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS total_cast
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year IS NOT NULL
),
MoviesWithKeywords AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        COALESCE(k.keyword, 'None') AS keyword
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
FilteredMovies AS (
    SELECT 
        mwk.movie_id,
        mwk.movie_title,
        mwk.production_year,
        mwk.keyword,
        CASE 
            WHEN mwk.production_year < 2000 THEN 'Classic'
            WHEN mwk.production_year >= 2000 AND mwk.production_year < 2010 THEN 'Modern'
            ELSE 'Recent'
        END AS movie_age_group
    FROM 
        MoviesWithKeywords mwk
    WHERE 
        mwk.keyword != 'None'
)
SELECT 
    f.movie_title,
    f.production_year,
    f.keyword,
    f.movie_age_group,
    COUNT(DISTINCT c.person_id) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
FROM 
    FilteredMovies f
LEFT JOIN 
    complete_cast cc ON f.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
WHERE 
    f.production_year >= 2000
GROUP BY 
    f.movie_id, f.movie_title, f.production_year, f.keyword, f.movie_age_group
HAVING 
    COUNT(DISTINCT c.person_id) > 3
ORDER BY 
    f.production_year DESC, f.movie_title ASC;
