WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_by_cast,
        COUNT(ci.person_id) AS total_cast
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id, t.title, t.production_year
),
CoActors AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci2.person_id) AS coactor_count
    FROM 
        cast_info ci
    INNER JOIN 
        cast_info ci2 ON ci.movie_id = ci2.movie_id AND ci.person_id <> ci2.person_id
    GROUP BY 
        ci.movie_id
),
DistinctKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords_list
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
    rm.rank_by_cast,
    COALESCE(ca.coactor_count, 0) AS unique_coactors,
    COALESCE(dk.keywords_list, 'No Keywords') AS keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    CoActors ca ON rm.title_id = ca.movie_id
LEFT JOIN 
    DistinctKeywords dk ON rm.title_id = dk.movie_id
WHERE 
    rm.total_cast > 5 OR (rm.rank_by_cast = 1 AND rm.total_cast IS NOT NULL)
ORDER BY 
    rm.production_year DESC, 
    rm.rank_by_cast ASC, 
    rm.total_cast DESC;
