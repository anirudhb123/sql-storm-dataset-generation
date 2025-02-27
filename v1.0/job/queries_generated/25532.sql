WITH movie_actors AS (
    SELECT 
        ca.movie_id,
        ak.name AS actor_name,
        ct.kind AS role_name,
        m.production_year
    FROM 
        cast_info ca
    JOIN 
        aka_name ak ON ca.person_id = ak.person_id
    JOIN 
        role_type ct ON ca.role_id = ct.id
    JOIN 
        title m ON ca.movie_id = m.id
), 
keyword_summary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), 
movie_companies_summary AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
), 
complete_info AS (
    SELECT 
        ma.movie_id,
        ma.actor_name,
        ma.role_name,
        ma.production_year,
        k.keywords_list,
        c.company_names,
        c.company_types
    FROM 
        movie_actors ma
    LEFT JOIN 
        keyword_summary k ON ma.movie_id = k.movie_id
    LEFT JOIN 
        movie_companies_summary c ON ma.movie_id = c.movie_id
)
SELECT 
    movie_id,
    actor_name,
    role_name,
    production_year,
    keywords_list,
    company_names,
    company_types
FROM 
    complete_info
WHERE 
    production_year >= 2000
ORDER BY 
    production_year DESC, actor_name;
