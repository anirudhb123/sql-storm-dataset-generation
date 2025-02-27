WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_type,
        k.keyword AS movie_keyword,
        ak.name AS actor_name,
        ak.imdb_index AS actor_imdb_index,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY ak.name) AS actor_order
    FROM 
        aka_title AS t
    JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
    JOIN 
        cast_info AS ci ON t.id = ci.movie_id
    JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
        AND ak.name IS NOT NULL
),

keyword_summary AS (
    SELECT 
        movie_title,
        production_year,
        string_agg(DISTINCT movie_keyword, ', ') AS keywords,
        string_agg(DISTINCT actor_name, ', ' ORDER BY actor_order) AS actors
    FROM 
        movie_details
    GROUP BY 
        movie_title, production_year
)

SELECT 
    movie_title,
    production_year,
    keywords,
    actors
FROM 
    keyword_summary
ORDER BY 
    production_year DESC, movie_title;
