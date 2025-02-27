WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rn
    FROM 
        aka_title t 
    WHERE 
        t.production_year IS NOT NULL
        AND t.title IS NOT NULL
),
FilteredPeople AS (
    SELECT 
        ak.person_id, 
        ak.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    LEFT JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    WHERE 
        ak.name IS NOT NULL 
        AND ak.name <> ''
    GROUP BY 
        ak.person_id, ak.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
MovieKeywords AS (
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
    rm.title AS movie_title,
    rm.production_year,
    fp.name AS person_name,
    fp.movie_count,
    mk.keywords
FROM 
    RankedMovies rm
INNER JOIN 
    FilteredPeople fp ON fp.movie_count >= 5
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    EXISTS (
        SELECT 1 
        FROM cast_info ci 
        WHERE ci.movie_id = rm.movie_id 
          AND ci.person_id = fp.person_id
          AND ci.nr_order = (
              SELECT MAX(nr_order)
              FROM cast_info 
              WHERE movie_id = rm.movie_id 
          )
    )
ORDER BY 
    rm.production_year DESC,
    fp.movie_count DESC,
    mk.keywords IS NULL
LIMIT 100;
