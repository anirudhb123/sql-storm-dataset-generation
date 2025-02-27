WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id
),
CharNameWithRoles AS (
    SELECT 
        cn.id AS char_id,
        cn.name,
        ci.role_id,
        ci.movie_id,
        ROW_NUMBER() OVER (PARTITION BY cn.id ORDER BY ci.nr_order) AS role_order
    FROM 
        char_name cn
    LEFT JOIN 
        cast_info ci ON ci.person_id = cn.imdb_id
),
SubqueryWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        m.id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    cwr.name AS character_name,
    cwr.role_order,
    COALESCE(skw.keywords, 'No keywords') AS movie_keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    CharNameWithRoles cwr ON rm.movie_id = cwr.movie_id AND cwr.role_order = 1
LEFT JOIN 
    SubqueryWithKeywords skw ON rm.movie_id = skw.movie_id
WHERE 
    rm.rank_by_cast <= 5
    AND (rm.production_year IS NOT NULL OR rm.cast_count > 0)
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;

-- Additionally: Any movie with no keywords and had more than 5 cast members will be highlighted.
WITH HighCastMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.cast_count > 5
)
SELECT 
    hcm.movie_id,
    hcm.title,
    hcm.production_year,
    'Highlight: Too many actors, no keywords' AS Remark
FROM 
    HighCastMovies hcm
LEFT JOIN 
    SubqueryWithKeywords skw ON hcm.movie_id = skw.movie_id
WHERE 
    skw.keywords IS NULL;


