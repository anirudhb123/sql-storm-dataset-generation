WITH MovieStats AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT cc.person_id) AS total_cast,
        AVG(CASE WHEN pi.info_type_id = 1 THEN LENGTH(pi.info) END) AS avg_person_info_length,
        DENSE_RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT cc.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title at
    LEFT JOIN 
        complete_cast cc ON at.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        person_info pi ON ci.person_id = pi.person_id
    GROUP BY 
        at.id, at.title, at.production_year 
),
FilteredMovies AS (
    SELECT 
        title,
        production_year,
        total_cast,
        avg_person_info_length
    FROM 
        MovieStats
    WHERE 
        rank_by_cast <= 5
)
SELECT 
    fm.title,
    fm.production_year,
    fm.total_cast,
    COALESCE(fm.avg_person_info_length, 0) AS avg_info_length,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = (SELECT id FROM aka_title WHERE title = fm.title LIMIT 1)) AS num_movie_infos,
    (SELECT STRING_AGG(DISTINCT cn.name, ', ') 
     FROM movie_companies mc
     JOIN company_name cn ON mc.company_id = cn.id
     WHERE mc.movie_id = (SELECT id FROM aka_title WHERE title = fm.title LIMIT 1)
     AND mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Production')) AS production_companies
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC, fm.total_cast DESC;
