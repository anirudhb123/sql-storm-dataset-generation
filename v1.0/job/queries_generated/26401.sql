WITH RankedTitles AS (
    SELECT 
        title.id AS title_id,
        title.title AS movie_title,
        title.production_year,
        COUNT(DISTINCT aka_name.person_id) AS actor_count,
        AVG(CASE WHEN company_type.kind = 'Distributor' THEN 1 ELSE 0 END) AS distributor_ratio,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS actors_list
    FROM 
        title
    LEFT JOIN 
        movie_companies ON title.id = movie_companies.movie_id
    LEFT JOIN 
        company_type ON movie_companies.company_type_id = company_type.id
    LEFT JOIN 
        cast_info ON title.id = cast_info.movie_id
    LEFT JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    GROUP BY 
        title.id, title.title, title.production_year
),
HighlightedTitles AS (
    SELECT 
        title_id,
        movie_title,
        production_year,
        actor_count,
        distributor_ratio,
        actors_list,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY actor_count DESC) AS year_rank
    FROM 
        RankedTitles
)
SELECT 
    *,
    CONCAT(movie_title, ' (', production_year, ') - Actors: ', actor_count, ' - Distributors: ', 
    ROUND(distributor_ratio * 100, 2), '%') AS title_summary
FROM 
    HighlightedTitles
WHERE 
    year_rank <= 5
ORDER BY 
    production_year DESC, actor_count DESC;
