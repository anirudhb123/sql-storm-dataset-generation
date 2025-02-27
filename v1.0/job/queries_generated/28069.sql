WITH MovieTitleKeywords AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        ARRAY_AGG(mk.keyword) AS keywords
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.id, mt.title
),
ActorInfo AS (
    SELECT 
        c.movie_id,
        ak.name AS actor_name,
        ak.person_id,
        r.role AS role_name
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mk.keywords,
        ai.actor_name,
        ai.role_name
    FROM 
        aka_title m
    LEFT JOIN 
        MovieTitleKeywords mk ON m.id = mk.movie_id
    LEFT JOIN 
        ActorInfo ai ON m.id = ai.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    STRING_AGG(DISTINCT md.actor_name || ' as ' || md.role_name, ', ') AS actors,
    md.keywords
FROM 
    MovieDetails md
WHERE 
    md.production_year BETWEEN 2000 AND 2023
GROUP BY 
    md.movie_id, md.title, md.production_year
ORDER BY 
    md.production_year DESC, md.title;
