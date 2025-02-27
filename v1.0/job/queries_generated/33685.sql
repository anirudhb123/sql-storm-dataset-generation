WITH RECURSIVE CTE_Movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY[m.title] AS title_path
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        cte.title_path || m.title
    FROM 
        aka_title m
    JOIN 
        CTE_Movies cte ON m.id = m.episode_of_id
),
Ranked_Cast AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL
),
Movie_Company_Info AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    mv.movie_id,
    mv.title,
    mv.production_year,
    string_agg(DISTINCT rc.actor_name, ', ') AS main_actors,
    COUNT(DISTINCT mc.company_name) AS total_companies,
    MAX(mv.production_year) OVER () AS latest_movie_year,
    SUM(CASE 
            WHEN mc.company_type = 'Production' THEN 1 
            ELSE 0 
        END) AS production_company_count,
    CASE 
        WHEN COUNT(DISTINCT mc.company_name) > 0 
        THEN 'Has Companies' 
        ELSE 'No Companies' 
    END AS company_info
FROM 
    CTE_Movies mv
LEFT JOIN 
    Ranked_Cast rc ON mv.movie_id = rc.movie_id AND rc.actor_rank <= 3
LEFT JOIN 
    Movie_Company_Info mc ON mv.movie_id = mc.movie_id
GROUP BY 
    mv.movie_id, 
    mv.title, 
    mv.production_year
ORDER BY 
    mv.production_year DESC, 
    mv.title;
