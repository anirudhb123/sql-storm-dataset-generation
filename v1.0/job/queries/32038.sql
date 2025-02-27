
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        1 AS level,
        m.title AS title,
        m.production_year AS production_year,
        NULL AS parent_title
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id AS movie_id,
        h.level + 1,
        e.title AS title,
        e.production_year AS production_year,
        h.title AS parent_title
    FROM 
        aka_title e
    JOIN 
        MovieHierarchy h ON e.episode_of_id = h.movie_id
), MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), ActorInfo AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(c.person_id) AS num_roles
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id, a.name
), MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COALESCE(ai.num_roles, 0) AS num_roles,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        MovieKeywords mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        ActorInfo ai ON mh.movie_id = ai.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.keywords,
    md.num_roles,
    CASE 
        WHEN md.num_roles = 0 THEN 'No Roles'
        ELSE CAST(md.num_roles AS TEXT)
    END AS role_info,
    (SELECT AVG(num_roles) FROM ActorInfo) AS average_roles,
    (SELECT COUNT(*) FROM aka_title) AS total_movies
FROM 
    MovieDetails md
WHERE 
    md.production_year > 2000
    AND md.rank <= 10
ORDER BY 
    md.production_year DESC, md.title;
