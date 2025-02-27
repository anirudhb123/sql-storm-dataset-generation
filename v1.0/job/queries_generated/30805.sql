WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.person_id, 
        a.name AS actor_name, 
        ct.kind AS role_type,
        1 AS level 
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        comp_cast_type ct ON c.person_role_id = ct.id
    WHERE 
        c.movie_id IN (SELECT id FROM aka_title WHERE production_year = 2020)
    
    UNION ALL

    SELECT 
        c.person_id, 
        a.name AS actor_name, 
        ct.kind AS role_type,
        ah.level + 1 
    FROM 
        cast_info c
    JOIN 
        ActorHierarchy ah ON c.movie_id IN (SELECT linked_movie_id FROM movie_link ml WHERE ml.movie_id = ah.movie_id)
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        comp_cast_type ct ON c.person_role_id = ct.id
), MovieDetails AS (
    SELECT 
        mt.title,
        a.actor_name,
        a.role_type,
        t.production_year,
        COALESCE(mk.keyword, 'No Keyword') AS keyword,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY a.level) AS actor_rank
    FROM 
        aka_title mt
    JOIN 
        cast_info c ON mt.id = c.movie_id
    JOIN 
        ActorHierarchy a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = mt.id
    JOIN 
        title t ON mt.id = t.id
    WHERE 
        a.actor_name IS NOT NULL
)
SELECT 
    md.title,
    md.actor_name,
    md.role_type,
    md.production_year,
    md.keyword,
    CASE 
        WHEN md.actor_rank = 1 THEN 'Lead Actor'
        WHEN md.actor_rank > 1 AND md.actor_rank <= 5 THEN 'Supporting Actor'
        ELSE 'Extra'
    END AS actor_classification
FROM 
    MovieDetails md
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, 
    md.actor_rank ASC;

