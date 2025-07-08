
WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        c.kind AS cast_kind,
        k.keyword AS genre,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title AS t
    JOIN 
        cast_info AS ci ON t.id = ci.movie_id
    JOIN 
        aka_name AS a ON a.person_id = ci.person_id
    LEFT JOIN 
        movie_companies AS mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name AS cn ON cn.id = mc.company_id
    LEFT JOIN 
        kind_type AS kt ON kt.id = t.kind_id
    LEFT JOIN 
        movie_keyword AS mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword AS k ON k.id = mk.keyword_id
    LEFT JOIN 
        comp_cast_type AS c ON c.id = ci.person_role_id
    WHERE 
        t.production_year >= 2000 
        AND t.title LIKE '%Action%' 
    GROUP BY 
        t.title, t.production_year, a.name, c.kind, k.keyword
    ORDER BY 
        t.production_year DESC, company_count DESC
)
SELECT 
    movie_title,
    production_year,
    actor_name,
    cast_kind,
    COUNT(DISTINCT genre) AS unique_genres,
    company_count
FROM 
    MovieDetails
GROUP BY 
    movie_title, production_year, actor_name, cast_kind, company_count
HAVING 
    company_count > 1
ORDER BY 
    production_year DESC;
