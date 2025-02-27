WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_within_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorStats AS (
    SELECT
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(COALESCE(CAST(mi.info AS FLOAT), 0)) AS avg_info_value
    FROM 
        cast_info ci
    LEFT JOIN 
        movie_info mi ON ci.movie_id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')
    GROUP BY 
        ci.person_id
),
NameVariations AS (
    SELECT 
        ak.name,
        ak.id AS aka_id,
        CHAR_LENGTH(ak.name) AS name_length
    FROM 
        aka_name ak
    WHERE 
        ak.name IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.id AS cast_id,
        n.name,
        rt.role,
        COALESCE(n.gender, 'Unknown') AS gender,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_rank
    FROM 
        cast_info c
    JOIN 
        name n ON c.person_id = n.imdb_id
    LEFT JOIN 
        role_type rt ON c.role_id = rt.id
)
SELECT 
    rm.movie_id,
    rm.title,
    ARRAY_AGG(DISTINCT ar.name ORDER BY ar.role_rank) AS actor_names,
    COUNT(DISTINCT ar.gender) FILTER (WHERE ar.gender = 'F') AS female_actors,
    COUNT(DISTINCT ar.gender) FILTER (WHERE ar.gender = 'M') AS male_actors,
    COALESCE(SUM(asv.movie_count), 0) AS total_actors,
    COALESCE(AVG(asv.avg_info_value), 0) AS average_box_office_info,
    nv.name_length,
    CASE 
        WHEN COUNT(DISTINCT ar.gender) = 0 THEN 'No actors'
        ELSE 'Actors available'
    END AS availability_status
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.cast_id
LEFT JOIN 
    ActorStats asv ON ar.name = asv.person_id::text
LEFT JOIN 
    NameVariations nv ON nv.name = ar.name
GROUP BY 
    rm.movie_id, rm.title, nv.name_length
HAVING 
    SUM(ar.role_rank) IS NOT NULL AND 
    MAX(rm.rank_within_year) < 5 
ORDER BY 
    rm.production_year DESC, 
    total_actors DESC
LIMIT 100;
