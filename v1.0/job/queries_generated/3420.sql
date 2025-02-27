WITH MovieDetails AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        a.kind_id,
        COALESCE(k.keyword, 'No Keyword') AS keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS row_num
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000
),
ActorDetails AS (
    SELECT 
        n.name AS actor_name,
        c.movie_id,
        a.name AS aka_name,
        COUNT(*) OVER (PARTITION BY n.id) AS total_roles
    FROM 
        name n
    JOIN 
        cast_info c ON n.id = c.person_id
    LEFT JOIN 
        aka_name a ON n.id = a.person_id
    WHERE 
        n.gender = 'M'
),
AggregateRoles AS (
    SELECT 
        ad.actor_name,
        COUNT(DISTINCT ad.movie_id) AS distinct_movies,
        SUM(ad.total_roles) AS total_roles_per_actor
    FROM 
        ActorDetails ad
    GROUP BY 
        ad.actor_name
)
SELECT 
    md.movie_title,
    md.production_year,
    a.actor_name,
    COALESCE(ar.distinct_movies, 0) AS actor_movie_count,
    ar.total_roles_per_actor,
    md.keyword
FROM 
    MovieDetails md
JOIN 
    cast_info ci ON md.id = ci.movie_id
LEFT JOIN 
    AggregateRoles ar ON ci.person_id = (SELECT person_id FROM name WHERE name = ar.actor_name LIMIT 1)
ORDER BY 
    md.production_year DESC, a.actor_name
LIMIT 100;
