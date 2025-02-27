WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.person_id,
        c.movie_id,
        a.name AS actor_name,
        1 AS level
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
    UNION ALL
    SELECT 
        c.person_id,
        c.movie_id,
        a.name AS actor_name,
        ah.level + 1
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        ActorHierarchy ah ON c.movie_id = ah.movie_id
    WHERE 
        ah.level < 3 -- Limit recursion depth
),
FilteredMovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    WHERE 
        mc.note IS NOT NULL OR mc.note != ''
    GROUP BY 
        mc.movie_id
),
RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        SUM(COALESCE(CASE WHEN mc.company_type_id IS NULL THEN 0 ELSE 1 END, 0)) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mk.keyword_id) DESC) as rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    GROUP BY 
        t.id
),
FinalResults AS (
    SELECT 
        ah.actor_name,
        rm.title,
        rm.production_year,
        rm.keyword_count,
        rm.company_count
    FROM 
        ActorHierarchy ah
    JOIN 
        RankedMovies rm ON ah.movie_id = rm.movie_id
    WHERE 
        rm.rank <= 5 -- Top 5 movies by keyword count for years
)
SELECT 
    actor_name,
    title,
    production_year,
    keyword_count,
    company_count
FROM 
    FinalResults
WHERE 
    actor_name IS NOT NULL
ORDER BY 
    production_year DESC, keyword_count DESC;
