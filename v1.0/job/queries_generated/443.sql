WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_by_title,
        COUNT(DISTINCT mc.company_id) OVER (PARTITION BY t.id) AS company_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    WHERE 
        t.production_year >= 2000
),
CastStats AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        SUM(CASE WHEN ci.nr_order = 1 THEN 1 ELSE 0 END) AS leading_roles
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
KeywordStats AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    cs.total_cast,
    cs.leading_roles,
    rm.company_count,
    ks.keywords,
    COALESCE(NULLIF(rm.rank_by_title, 0), 'Not Ranked') AS rank_status
FROM 
    RankedMovies rm
LEFT JOIN 
    CastStats cs ON rm.movie_id = cs.movie_id
LEFT JOIN 
    KeywordStats ks ON rm.movie_id = ks.movie_id
WHERE 
    cs.total_cast IS NOT NULL
ORDER BY 
    rm.production_year DESC, 
    rm.rank_by_title;
