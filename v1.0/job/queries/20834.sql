
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_within_year
    FROM
        aka_title t
    LEFT JOIN
        cast_info ci ON t.id = ci.movie_id
    GROUP BY
        t.id, t.title, t.production_year
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
NullTesting AS (
    SELECT 
        t.id AS title_id,
        COALESCE(NULLIF(t.title, ''), 'Untitled') AS safe_title,
        CASE 
            WHEN t.production_year IS NULL THEN 'Year Unknown'
            ELSE CAST(t.production_year AS VARCHAR)
        END AS production_year_safe
    FROM 
        aka_title t
)
SELECT 
    rm.title,
    rm.production_year,
    rm.total_cast,
    mk.keywords,
    nt.safe_title,
    nt.production_year_safe
FROM 
    RankedMovies rm
    LEFT JOIN MovieKeywords mk ON rm.title_id = mk.movie_id
    LEFT JOIN NullTesting nt ON rm.title_id = nt.title_id
WHERE 
    rm.rank_within_year <= 5 
    AND (rm.production_year >= 2000 OR rm.production_year IS NULL)
ORDER BY 
    rm.production_year DESC, 
    rm.total_cast DESC;
