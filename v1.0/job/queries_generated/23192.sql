WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id, 
        title.title, 
        title.production_year, 
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.title) AS ranking
    FROM 
        title
    WHERE 
        title.production_year IS NOT NULL
),
PersonRole AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role,
        COUNT(*) OVER (PARTITION BY ci.movie_id, rt.id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(k.keyword, ', ') AS all_keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(pk.all_keywords, 'No Keywords') AS keywords,
        COALESCE(pr.actor_name, 'Unknown Actor') AS lead_actor,
        COALESCE(pr.role, 'No Role') AS role,
        COUNT(pr.role) AS total_roles
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords pk ON rm.movie_id = pk.movie_id
    LEFT JOIN 
        PersonRole pr ON rm.movie_id = pr.movie_id
    WHERE 
        rm.ranking <= 3 AND 
        (rm.production_year BETWEEN 2000 AND 2023 OR rm.production_year IS NULL)
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, pk.all_keywords, pr.actor_name, pr.role
) 
SELECT 
    fm.title,
    fm.production_year,
    fm.keywords,
    fm.lead_actor,
    fm.role,
    fm.total_roles
FROM 
    FilteredMovies fm
WHERE 
    (fm.role_count IS NULL OR fm.role_count <= 3)
ORDER BY 
    fm.production_year DESC, 
    fm.title ASC;

This query uses Common Table Expressions (CTEs) to organize the logic into manageable parts, starting from building ranked movies to gathering associated actors and keywords. It leverages window functions, outer joins, string aggregation, and NULL handling to construct a comprehensive view of the top movies based on their production years, including their roles and associated keywords. The final output fetches movies released between 2000 and 2023, while applying additional filtering and sorting for a neat presentation.
