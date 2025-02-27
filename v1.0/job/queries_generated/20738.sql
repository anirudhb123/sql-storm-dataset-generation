WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_in_year
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT
        ci.movie_id,
        ci.person_id,
        CASE 
            WHEN r.role IS NULL THEN 'Unknown Role'
            ELSE r.role 
        END AS role_description,
        DENSE_RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM
        cast_info ci
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ar.person_id,
        ar.role_description,
        ar.role_rank
    FROM
        RankedMovies rm
    LEFT JOIN
        ActorRoles ar ON rm.movie_id = ar.movie_id
    WHERE
        rm.title_rank <= 10 -- Only consider top 10 titles per year
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(n.name, 'No Name') AS actor_name,
    COUNT(DISTINCT md.person_id) OVER (PARTITION BY md.production_year) AS distinct_actors_count,
    SUM(CASE 
            WHEN md.role_rank = 1 THEN 1 
            ELSE 0 
        END) OVER (PARTITION BY md.movie_id) AS lead_role_count,
    STRING_AGG(DISTINCT md.role_description, ', ') AS roles
FROM
    MovieDetails md
LEFT JOIN
    name n ON md.person_id = n.id
GROUP BY 
    md.title, md.production_year, n.name
ORDER BY 
    md.production_year DESC, md.title ASC
LIMIT 100;

-- Exploring NULL logic and corner cases
SELECT 
    COALESCE(k.keyword, 'No Keywords') AS keyword,
    COUNT(DISTINCT ki.movie_id) AS movies_count
FROM 
    movie_keyword ki
FULL OUTER JOIN 
    keyword k ON ki.keyword_id = k.id
WHERE 
    k.keyword IS NULL OR ki.movie_id IS NOT NULL
GROUP BY 
    k.keyword
HAVING 
    COUNT(DISTINCT ki.movie_id) > 5
ORDER BY 
    movies_count DESC;

-- Using SET operators for different movie types
SELECT 
    'Movie' AS type,
    t.title,
    t.production_year
FROM 
    aka_title t
WHERE 
    t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')

UNION ALL

SELECT 
    'Series' AS type,
    t.title,
    t.production_year
FROM 
    aka_title t
WHERE 
    t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'series')
ORDER BY 
    type, production_year DESC;

