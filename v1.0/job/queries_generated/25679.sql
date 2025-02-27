WITH ActorRoles AS (
    SELECT 
        ka.person_id,
        ka.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS total_movies,
        STRING_AGG(DISTINCT t.title, ', ') AS movie_titles
    FROM 
        aka_name ka
    JOIN 
        cast_info c ON ka.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    GROUP BY 
        ka.person_id, ka.name
), 
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mt.kind AS movie_type,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM 
        aka_title m
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        m.id, m.title, m.production_year, mt.kind
), 
Popularity AS (
    SELECT 
        m.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        m.movie_id
)
SELECT 
    ar.actor_name,
    ar.total_movies,
    ar.movie_titles,
    md.title AS movie_title,
    md.production_year,
    md.movie_type,
    COALESCE(p.keyword_count, 0) AS keyword_count
FROM 
    ActorRoles ar
JOIN 
    MovieDetails md ON md.movie_id = ANY(ARRAY(SELECT movie_id FROM cast_info WHERE person_id = ar.person_id))
LEFT JOIN 
    Popularity p ON md.movie_id = p.movie_id
ORDER BY 
    ar.total_movies DESC, 
    keyword_count DESC
LIMIT 100;
