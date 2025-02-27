WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
MovieDetails AS (
    SELECT 
        at.title,
        at.production_year,
        COALESCE(mo.info, 'No Info') AS movie_info,
        COALESCE(GROUP_CONCAT(DISTINCT cn.name), 'No Companies') AS companies
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info mo ON rm.title = mo.info
    LEFT JOIN 
        movie_companies mc ON rm.title = (SELECT title FROM aka_title WHERE id = mc.movie_id)
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        rm.rn <= 5
    GROUP BY 
        at.id, at.title, at.production_year, mo.info
)
SELECT 
    md.title,
    md.production_year,
    md.movie_info,
    md.companies,
    SUM(CASE WHEN pi.info_type_id = 1 THEN 1 ELSE 0 END) AS total_awards,
    AVG(CASE WHEN pi.info_type_id = 2 THEN pi.info::integer END) AS average_rating
FROM 
    MovieDetails md
LEFT JOIN 
    movie_info pi ON md.title = (SELECT title FROM aka_title WHERE id = pi.movie_id) 
GROUP BY 
    md.title, md.production_year, md.movie_info, md.companies
ORDER BY 
    md.production_year DESC, total_awards DESC;
