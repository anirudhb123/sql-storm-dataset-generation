WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        MAX(CASE WHEN ci.note LIKE '%leading%' THEN 1 ELSE 0 END) AS has_leading_actor
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
CompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),
MovieInfoSummary AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS all_info
    FROM 
        movie_info mi
    WHERE 
        EXISTS (SELECT 1 FROM info_type it WHERE it.id = mi.info_type_id AND it.info LIKE '%compilation%')
    GROUP BY
        mi.movie_id
)

SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    ac.actor_count,
    ac.has_leading_actor,
    cc.company_count,
    COALESCE(mis.all_info, 'No compilation info') AS compilation_info
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorCounts ac ON rm.movie_id = ac.movie_id
LEFT JOIN 
    CompanyCounts cc ON rm.movie_id = cc.movie_id
LEFT JOIN 
    MovieInfoSummary mis ON rm.movie_id = mis.movie_id
WHERE
    rm.year_rank <= 5  -- Get top 5 movies per production year
    AND (ac.actor_count IS NULL OR ac.actor_count >= 3)  -- Ensure at least 3 actors or none at all
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;

WITH RECURSIVE CompanyHierarchy AS (
    SELECT 
        id, 
        name, 
        country_code, 
        NULL::integer AS parent_id
    FROM 
        company_name
    WHERE 
        country_code = 'USA'

    UNION ALL

    SELECT 
        cn.id,
        cn.name,
        cn.country_code,
        ch.id
    FROM 
        company_name cn
    INNER JOIN 
        CompanyHierarchy ch ON cn.imdb_id = ch.parent_id
)

SELECT 
    ch.name AS company_name,
    (SELECT COUNT(*) FROM movie_companies mc WHERE mc.company_id = ch.id) AS movie_count
FROM 
    CompanyHierarchy ch
WHERE 
    EXISTS (SELECT 1 FROM movie_companies mc WHERE mc.company_id = ch.id AND mc.note IS NOT NULL)
ORDER BY 
    movie_count DESC;

SELECT 
    name,
    COUNT(*) AS count
FROM 
    (SELECT 
        COALESCE(a.name, 'Unknown') AS name
     FROM 
        aka_name a
     FULL OUTER JOIN 
        aka_title at ON a.id = at.id
     WHERE 
        a.name IS NOT NULL 
        AND (a.name LIKE '%The%' OR at.title LIKE '%The%') -- Bizarre semantic condition
     ) AS combined_names
GROUP BY 
    name
HAVING 
    COUNT(*) > 5;
