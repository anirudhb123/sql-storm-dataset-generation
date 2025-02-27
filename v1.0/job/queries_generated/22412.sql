WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
), SelectedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        CASE 
            WHEN rm.cast_count > 10 THEN 'Large'
            WHEN rm.cast_count BETWEEN 5 AND 10 THEN 'Medium'
            ELSE 'Small'
        END AS cast_size
    FROM 
        RankedMovies rm
    WHERE 
        rm.year_rank <= 3   -- Select top 3 movies per year
), MovieDetails AS (
    SELECT 
        sm.*,
        COALESCE(mo.info, 'No information available') AS additional_info,
        STRING_AGG(DISTINCT cn.name, ', ') AS production_companies
    FROM 
        SelectedMovies sm
    LEFT JOIN 
        movie_info mo ON mo.movie_id = sm.movie_id AND mo.info_type_id = (SELECT id FROM info_type WHERE info = 'Summary')
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = sm.movie_id
    LEFT JOIN 
        company_name cn ON cn.id = mc.company_id
    GROUP BY 
        sm.movie_id, sm.title, sm.production_year, sm.cast_count
), ActorsWithRoles AS (
    SELECT 
        na.name AS actor_name,
        ci.movie_id,
        rt.role AS actor_role
    FROM 
        cast_info ci
    JOIN 
        aka_name na ON na.person_id = ci.person_id
    JOIN 
        role_type rt ON rt.id = ci.role_id
    WHERE 
        na.name IS NOT NULL
), FinalOutput AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_count,
        md.additional_info,
        md.production_companies,
        COUNT(DISTINCT awr.actor_name) AS actor_count,
        ARRAY_AGG(DISTINCT awr.actor_name) AS actors
    FROM 
        MovieDetails md
    LEFT JOIN 
        ActorsWithRoles awr ON awr.movie_id = md.movie_id
    GROUP BY 
        md.movie_id, md.title, md.production_year, md.cast_count, md.additional_info, md.production_companies
)

SELECT 
    *,
    CASE 
        WHEN actor_count > 0 THEN TRUE
        ELSE FALSE
    END AS has_actors,
    RANK() OVER (ORDER BY production_year DESC, cast_count DESC) AS rank_by_cast
FROM 
    FinalOutput
ORDER BY 
    production_year DESC, actor_count DESC;
