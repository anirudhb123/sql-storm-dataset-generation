WITH detailed_movie_info AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS keyword,
        ak.name AS actor_name,
        ak.imdb_index AS actor_imdb_index,
        ct.kind AS company_type,
        cn.name AS company_name
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        t.production_year >= 2000
        AND k.keyword ILIKE '%action%'
),
aggregated_info AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        STRING_AGG(DISTINCT keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors,
        COUNT(DISTINCT company_name) AS company_count
    FROM 
        detailed_movie_info
    GROUP BY 
        movie_id, movie_title, production_year
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    keywords,
    actors,
    company_count
FROM 
    aggregated_info
ORDER BY 
    production_year DESC, company_count DESC;
