WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        co.name AS company_name,
        ct.kind AS company_type,
        a.name AS actor_name,
        p.gender AS actor_gender,
        COUNT(DISTINCT c.person_id) AS total_actors,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords_list
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        name p ON a.person_id = p.imdb_id
    WHERE 
        t.production_year >= 2000 
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'series'))
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword, co.name, ct.kind, a.name, p.gender
)

SELECT 
    movie_id,
    movie_title,
    production_year,
    COUNT(DISTINCT actor_name) AS actor_count,
    COUNT(DISTINCT company_name) AS production_company_count,
    STRING_AGG(DISTINCT keywords_list, '; ') AS all_keywords
FROM 
    MovieDetails
GROUP BY 
    movie_id, movie_title, production_year
ORDER BY 
    production_year DESC, actor_count DESC;
