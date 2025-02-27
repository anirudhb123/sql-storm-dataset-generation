WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        c.kind AS comp_type,
        a.name AS actor_name,
        COUNT(DISTINCT c.id) AS num_companies,
        COUNT(DISTINCT mk.id) AS num_keywords
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword, c.kind, a.name
),
ActorDetails AS (
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS total_movies,
        STRING_AGG(DISTINCT md.info, ', ') AS movie_infos
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        movie_info md ON ci.movie_id = md.movie_id
    GROUP BY 
        a.name
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keyword,
    md.comp_type,
    ad.actor_name,
    ad.total_movies,
    ad.movie_infos
FROM 
    MovieDetails md
JOIN 
    ActorDetails ad ON md.actor_name = ad.actor_name
ORDER BY 
    md.production_year DESC, md.title ASC;
