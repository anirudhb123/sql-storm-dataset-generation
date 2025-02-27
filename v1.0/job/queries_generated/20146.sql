WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COALESCE(SUM(CASE WHEN c.movie_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COALESCE(SUM(CASE WHEN c.movie_id IS NOT NULL THEN 1 ELSE 0 END), 0) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
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
), 
ActorInfo AS (
    SELECT 
        a.person_id,
        a.name,
        pi.info AS birth_date,
        row_number() OVER (ORDER BY a.name) AS actor_rank
    FROM 
        aka_name a
    LEFT JOIN 
        person_info pi ON a.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'birth date')
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    mk.keywords,
    ai.name AS actor_name,
    ai.birth_date,
    CASE 
        WHEN rm.cast_count > 5 THEN 'Highly Cast'
        WHEN rm.cast_count BETWEEN 3 AND 5 THEN 'Moderately Cast'
        ELSE 'Low Cast'
    END AS cast_quality,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM movie_companies mc 
            WHERE mc.movie_id = rm.movie_id 
              AND mc.note IS NOT NULL
        ) THEN 'Company Involvement'
        ELSE 'No Company Info'
    END AS company_info
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    cast_info ci ON rm.movie_id = ci.movie_id
LEFT JOIN 
    ActorInfo ai ON ci.person_id = ai.person_id
WHERE 
    (rm.rank <= 3 OR mk.keywords IS NOT NULL)  -- Showing top 3 ranked movies or movies with keywords
    AND (rm.cast_count IS NULL OR rm.cast_count > 2)  -- Filter out movies without cast or with very few cast
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
