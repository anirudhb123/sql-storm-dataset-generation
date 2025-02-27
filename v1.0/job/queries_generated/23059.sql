WITH RECURSIVE ActorRelationships AS (
    SELECT 
        ca.person_id,
        ca.movie_id,
        1 AS depth
    FROM 
        cast_info ca
    WHERE 
        ca.role_id IS NOT NULL
    UNION ALL
    SELECT 
        ca.person_id,
        ca.movie_id,
        ar.depth + 1
    FROM 
        cast_info ca
    JOIN 
        ActorRelationships ar ON ca.movie_id = ar.movie_id
    WHERE 
        ca.person_id <> ar.person_id
),
MovieDetails AS (
    SELECT 
        mt.title,
        mt.production_year,
        mt.kind_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY mt.production_year DESC) AS rn
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.movie_id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        mt.production_year >= 2000
    AND 
        ak.name IS NOT NULL
),
MovieInfo AS (
    SELECT 
        mv.title,
        mv.production_year,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_list,
        SUM(CASE WHEN mi.info_type_id = 1 THEN 1 ELSE 0 END) AS has_awards
    FROM 
        movie_info mi
    JOIN 
        aka_title mv ON mv.id = mi.movie_id
    JOIN 
        cast_info ci ON mv.movie_id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        mv.title, mv.production_year
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.total_actors, 0) AS total_actors,
    md.actor_list,
    CASE 
        WHEN md.has_awards > 0 THEN 'Awarded'
        ELSE 'No Awards'
    END AS award_status,
    COUNT(DISTINCT ar.person_id) AS relationship_count
FROM 
    MovieDetails md
LEFT JOIN 
    ActorRelationships ar ON md.actor_name = ar.person_id
GROUP BY 
    md.title, md.production_year, md.actor_list, md.has_awards
HAVING 
    COUNT(DISTINCT ar.person_id) > 1 
    OR (md.production_year IS NOT NULL AND md.production_year < EXTRACT(YEAR FROM CURRENT_DATE) - 5)
ORDER BY 
    md.production_year DESC, total_actors DESC;
