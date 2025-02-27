WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY t.id DESC) AS year_rank
    FROM 
        aka_title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
cast_details AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS num_actors,
        STRING_AGG(ak.name, ', ') AS actor_names
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
movie_companies_info AS (
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
)
SELECT 
    rt.title,
    rt.production_year,
    COALESCE(cd.num_actors, 0) AS total_actors,
    COALESCE(cd.actor_names, 'No cast available') AS actors,
    COALESCE(mci.company_names, 'No companies') AS companies,
    COALESCE(mci.company_types, 'No types') AS types
FROM 
    ranked_titles rt
LEFT JOIN 
    cast_details cd ON rt.title_id = cd.movie_id
LEFT JOIN 
    movie_companies_info mci ON rt.title_id = mci.movie_id
WHERE 
    rt.year_rank = 1
ORDER BY 
    rt.production_year DESC, rt.title;
