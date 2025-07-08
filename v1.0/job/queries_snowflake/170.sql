
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
MoviesWithKeywords AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(k.keyword, 'No Keyword') AS movie_keyword,
        rm.rank_by_cast
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    mwk.movie_id,
    mwk.title,
    mwk.production_year,
    mwk.movie_keyword,
    COALESCE(mw.total_roles, 0) AS total_roles,
    CASE 
        WHEN mwk.production_year < 2000 THEN 'Classic'
        WHEN mwk.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM 
    MoviesWithKeywords mwk
LEFT JOIN (
    SELECT 
        movie_id,
        COUNT(DISTINCT role_id) AS total_roles
    FROM 
        cast_info
    GROUP BY 
        movie_id
) mw ON mwk.movie_id = mw.movie_id
WHERE 
    mwk.rank_by_cast = 1
ORDER BY 
    mwk.production_year DESC, 
    mwk.title ASC;
