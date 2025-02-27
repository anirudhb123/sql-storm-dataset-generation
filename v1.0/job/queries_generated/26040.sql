WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        cn.name AS company_name,
        kt.kind AS kind_type,
        ak.name AS actor_name,
        rk.role AS role_type,
        GROUP_CONCAT(DISTINCT kw.keyword ORDER BY kw.keyword) AS keywords
    FROM 
        aka_title AS t
    JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    JOIN 
        aka_name AS ak ON ak.person_id IN (
            SELECT person_id FROM cast_info WHERE movie_id = t.id
        )
    JOIN 
        role_type AS rk ON rk.id = (SELECT person_role_id FROM cast_info WHERE movie_id = t.id AND person_id = ak.person_id LIMIT 1)
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS kw ON mk.keyword_id = kw.id
    WHERE 
        t.production_year >= 2000 AND
        ak.name IS NOT NULL
    GROUP BY 
        t.id, cn.name, kt.kind, ak.name, rk.role
),
ranked_movies AS (
    SELECT 
        md.*,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.movie_title) AS rank_within_year
    FROM 
        movie_details AS md
)

SELECT 
    *
FROM 
    ranked_movies
WHERE 
    rank_within_year < 6
ORDER BY 
    production_year DESC, rank_within_year;
