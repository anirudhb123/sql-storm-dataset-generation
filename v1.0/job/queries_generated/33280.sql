WITH RECURSIVE MovieHierarchy AS (
    -- Base case: Select all movies at the top level
    SELECT 
        m.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name c ON c.id = mc.company_id
    WHERE 
        mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Production')

    UNION ALL
    
    -- Recursive case: Join back to find sequels or related movies
    SELECT 
        mh.movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title t ON ml.linked_movie_id = t.id
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'sequel' LIMIT 1) -- Adjust to your criteria
),
ActorRoles AS (
    SELECT 
        a.person_id,
        a.name,
        ci.movie_id,
        rt.role as role
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        COUNT(DISTINCT ar.person_id) AS actor_count,
        STRING_AGG(DISTINCT ar.role, ', ') AS roles
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        ActorRoles ar ON mh.movie_id = ar.movie_id
    GROUP BY 
        mh.movie_id, mh.movie_title, mh.production_year
)
SELECT 
    md.movie_title,
    md.production_year,
    md.actor_count,
    md.roles,
    CASE 
        WHEN md.production_year IS NULL THEN 'Unknown Year'
        ELSE md.production_year::TEXT
    END AS production_year_label,
    COALESCE(md.actor_count, 0) AS actor_amount,
    ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.actor_count DESC) AS rank_within_year
FROM 
    MovieDetails md
WHERE 
    md.actor_count > 0
ORDER BY 
    md.production_year DESC, md.actor_count DESC;
