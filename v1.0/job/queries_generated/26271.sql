WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        AVG(CASE WHEN ci.person_role_id = rt.id THEN 1 ELSE 0 END) AS avg_actor_rating,
        ARRAY_AGG(DISTINCT an.name ORDER BY an.name) AS actor_names,
        ARRAY_AGG(DISTINCT k.keyword ORDER BY k.keyword) AS movie_keywords,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mi.info_type_id) AS info_type_count
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON ci.movie_id = mt.id
    JOIN 
        role_type rt ON ci.person_role_id = rt.id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    JOIN 
        movie_keyword mk ON mk.movie_id = mt.id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON mc.movie_id = mt.id
    JOIN 
        movie_info mi ON mi.movie_id = mt.id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        movie_title, 
        production_year, 
        avg_actor_rating, 
        actor_names, 
        movie_keywords, 
        company_count, 
        info_type_count,
        ROW_NUMBER() OVER (ORDER BY avg_actor_rating DESC, production_year DESC) AS rank
    FROM 
        RankedMovies
)

SELECT 
    movie_id,
    movie_title,
    production_year,
    avg_actor_rating,
    actor_names,
    movie_keywords,
    company_count,
    info_type_count
FROM 
    TopMovies
WHERE 
    rank <= 10
ORDER BY 
    avg_actor_rating DESC;
