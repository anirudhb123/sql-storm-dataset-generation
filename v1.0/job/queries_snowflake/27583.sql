
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        LISTAGG(DISTINCT ak.name, ', ') AS alias_names,
        LISTAGG(DISTINCT kw.keyword, ', ') AS keywords,
        LISTAGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        aka_title AS t
    LEFT JOIN 
        cast_info AS c ON t.movie_id = c.movie_id
    LEFT JOIN 
        aka_name AS ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword AS mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword AS kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name AS cn ON mc.company_id = cn.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),

Ranking AS (
    SELECT 
        movie_id, 
        title,
        production_year,
        actor_count,
        alias_names,
        keywords,
        company_names,
        RANK() OVER (ORDER BY actor_count DESC, production_year DESC) AS rank
    FROM 
        MovieDetails
)

SELECT 
    rank, 
    movie_id, 
    title, 
    production_year, 
    actor_count, 
    alias_names, 
    keywords, 
    company_names
FROM 
    Ranking
WHERE 
    rank <= 10
ORDER BY 
    rank;
