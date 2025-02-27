WITH MovieDetails AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        ak.name AS actor_name,
        ak.imdb_index AS actor_index,
        rt.role AS actor_role,
        cn.name AS company_name,
        ci.nr_order AS role_order
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        mt.production_year BETWEEN 2000 AND 2023
        AND ak.name IS NOT NULL
),
KeywordDetails AS (
    SELECT 
        md.movie_title,
        md.production_year,
        GROUP_CONCAT(mk.keyword) AS keywords
    FROM 
        MovieDetails md
    JOIN 
        movie_keyword mk ON md.movie_title = mk.movie_id
    GROUP BY 
        md.movie_title, md.production_year
),
FinalResults AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.actor_name,
        md.actor_index,
        md.actor_role,
        kd.keywords,
        COUNT(DISTINCT md.company_name) AS company_count
    FROM 
        MovieDetails md
    LEFT JOIN 
        KeywordDetails kd ON md.movie_title = kd.movie_title AND md.production_year = kd.production_year
    GROUP BY 
        md.movie_title, md.production_year, md.actor_name, md.actor_index, md.actor_role, kd.keywords
    ORDER BY 
        md.production_year DESC, md.movie_title
)
SELECT 
    movie_title,
    production_year,
    actor_name,
    actor_index,
    actor_role,
    keywords,
    company_count
FROM 
    FinalResults
WHERE 
    company_count > 1
ORDER BY 
    production_year, movie_title;
