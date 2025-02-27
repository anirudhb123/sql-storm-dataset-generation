
WITH movie_data AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ak.name AS actor_name,
        ak.imdb_index AS actor_imdb_index,
        COUNT(DISTINCT mc.company_id) AS production_companies,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT CAST(ci.role_id AS TEXT), ', ') AS roles
    FROM 
        aka_title AS t
    JOIN 
        cast_info AS ci ON t.id = ci.movie_id
    JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS kw ON mk.keyword_id = kw.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title, t.production_year, ak.name, ak.imdb_index
),
ranked_movies AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.actor_name,
        md.actor_imdb_index,
        md.production_companies,
        md.keywords,
        md.roles,
        RANK() OVER (PARTITION BY md.production_year ORDER BY md.production_companies DESC) AS rank
    FROM 
        movie_data md
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.actor_name,
    rm.actor_imdb_index,
    rm.production_companies,
    rm.keywords,
    rm.roles
FROM 
    ranked_movies rm
WHERE 
    rm.rank = 1
ORDER BY 
    rm.production_year DESC;
