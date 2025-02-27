WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
ActorRoles AS (
    SELECT 
        a.person_id,
        a.name,
        ci.movie_id,
        r.role AS actor_role,
        COUNT(*) OVER (PARTITION BY a.person_id ORDER BY ci.nr_order) AS role_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
),
CompanyMovieInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COALESCE(NULLIF(m.info, ''), 'N/A') AS movie_info
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_info m ON mc.movie_id = m.movie_id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot' LIMIT 1)
)
SELECT 
    rm.movie_title,
    rm.production_year,
    ar.name AS actor_name,
    ar.actor_role,
    ar.role_count,
    cmi.company_name,
    cmi.company_type,
    cmi.movie_info,
    CASE 
        WHEN rm.movie_keyword IS NOT NULL THEN 'Contains Keyword'
        ELSE 'No Keyword'
    END AS keyword_status,
    COUNT(*) OVER (PARTITION BY rm.production_year ORDER BY rm.movie_title) AS movies_per_year
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.year_rank = 1  -- Only taking the top-ranked year movies with actors
LEFT JOIN 
    CompanyMovieInfo cmi ON rm.production_year = (SELECT production_year FROM aka_title WHERE id = cmi.movie_id LIMIT 1)
WHERE 
    (ar.role_count > 1 OR ar.actor_role IS NULL)
    AND (rm.movie_keyword IS NOT NULL OR rm.movie_keyword IS NULL)
ORDER BY 
    rm.production_year DESC, rm.movie_title ASC;

**Explanation of the Query Constructs:**

1. **CTEs** (`WITH` clause): 
   - `RankedMovies`: Ranks movies by their production year and includes any associated keywords.
   - `ActorRoles`: Joins actors to their movie roles, counting how many roles each actor has, utilizing a window function to partition by `person_id`.
   - `CompanyMovieInfo`: Fetches company details related to the movies, handling `NULL` values with `COALESCE` and `NULLIF` to provide a fallback when certain data may be missing.

2. **LEFT JOINs**: Used extensively to maintain all movies in the result set, even when associated actors or companies might be missing.

3. **CASE statement**: Classifies movies based on the presence of keywords using complex conditional logic.

4. **COUNT(*) with WINDOW FUNCTION**: Calculates the number of movies per year by ordering in descending production year, offering insights into productions over time.

5. **Complicated WHERE clause**: Combines several logical conditions with `OR` and nested `SELECT` statements, showcasing a combination of checks for actor roles and keyword existence.

This SQL query aims to retrieve a comprehensive view of movies, their keywords, associated actors, and production companies, while also showing clear benchmarks for performance.
