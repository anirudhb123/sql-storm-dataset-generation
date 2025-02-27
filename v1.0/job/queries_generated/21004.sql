WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_per_year
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
        STRING_AGG(k.keyword, ', ' ORDER BY k.keyword) AS all_keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    ak.name AS actor_name,
    rm.title AS movie_title,
    rm.production_year,
    rk.all_keywords,
    ci.note AS cast_note,
    (SELECT COUNT(DISTINCT mci.company_id)
     FROM movie_companies mci 
     WHERE mci.movie_id = rm.movie_id) AS company_count,
    CASE
        WHEN rm.production_year IS NULL THEN 'Unknown Year'
        ELSE TO_CHAR(rm.production_year)
    END AS year_display,
    COALESCE(ct.kind, 'No Role Assigned') AS role_assignment,
    CASE 
        WHEN rm.rank_per_year = 1 THEN 'Top Movie of Year'
        ELSE NULL 
    END AS rank_description
FROM 
    RankedMovies rm
JOIN 
    cast_info ci ON rm.movie_id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    role_type ct ON ci.role_id = ct.id
LEFT JOIN 
    MovieKeywords rk ON rm.movie_id = rk.movie_id
WHERE 
    rm.rank_per_year <= 5 AND
    (ci.note IS NOT NULL OR rm.production_year > 2000)
ORDER BY 
    rm.production_year DESC, 
    rm.rank_per_year ASC
LIMIT 50 OFFSET 0;

WITH ActorMovies AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 10
)
SELECT 
    ak.name AS actor_name,
    am.movie_count,
    COALESCE(CAST(AVG(CASE WHEN mk.all_keywords IS NOT NULL THEN 1 ELSE 0 END) AS DECIMAL), 0) AS avg_keywords_per_actor
FROM 
    ActorMovies am
JOIN 
    aka_name ak ON am.person_id = ak.person_id
LEFT JOIN 
    MovieKeywords mk ON ak.person_id IN (
        SELECT ci.person_id 
        FROM cast_info ci 
        WHERE ci.movie_id IN (
            SELECT id 
            FROM aka_title 
            WHERE production_year >= 2000
        )
    )
GROUP BY 
    ak.name, am.movie_count
HAVING 
    avg_keywords_per_actor > 0.5
ORDER BY 
    avg_keywords_per_actor DESC;

-- Example edge case dealing with NULL logic; treating NULL production years differently
SELECT 
    t.title, 
    COALESCE(t.production_year::text, 'N/A') AS production_year_display
FROM 
    aka_title t
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM cast_info ci 
        WHERE ci.movie_id = t.id 
        AND ci.note IS NULL
    )
ORDER BY 
    t.production_year DESC NULLS LAST;
