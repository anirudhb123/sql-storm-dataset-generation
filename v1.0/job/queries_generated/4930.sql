WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS year_rank
    FROM
        aka_title at
    JOIN
        cast_info ci ON at.id = ci.movie_id
    GROUP BY
        at.title, at.production_year
),
FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actor_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.actor_count > (
            SELECT AVG(actor_count) 
            FROM RankedMovies 
            WHERE production_year IS NOT NULL
        )
),
MovieDetails AS (
    SELECT 
        fm.title,
        fm.production_year,
        mi.info AS movie_info,
        COALESCE(GROUP_CONCAT(DISTINCT co.name), 'No Companies') AS production_companies
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = (
            SELECT id FROM aka_title WHERE title = fm.title AND production_year = fm.production_year LIMIT 1
        )
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = (
            SELECT id FROM aka_title WHERE title = fm.title AND production_year = fm.production_year LIMIT 1
        ) AND mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%achievement%')
    GROUP BY 
        fm.title, fm.production_year, mi.info
)
SELECT 
    md.title,
    md.production_year,
    md.movie_info,
    md.production_companies,
    COUNT(DISTINCT ci.person_id) AS total_actors,
    RANK() OVER (ORDER BY md.production_year) AS production_year_rank
FROM 
    MovieDetails md
LEFT JOIN 
    cast_info ci ON ci.movie_id = (
        SELECT id FROM aka_title WHERE title = md.title AND production_year = md.production_year LIMIT 1
    )
GROUP BY 
    md.title, md.production_year, md.movie_info, md.production_companies
HAVING 
    COUNT(DISTINCT ci.person_id) >= 5
ORDER BY 
    md.production_year DESC, total_actors DESC;
