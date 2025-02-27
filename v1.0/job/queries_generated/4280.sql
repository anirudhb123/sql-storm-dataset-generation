WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        a.kind_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        a.production_year IS NOT NULL 
        AND a.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
    GROUP BY 
        a.title, a.production_year, a.kind_id
), PopularMovies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rn <= 10
), MovieDetails AS (
    SELECT 
        pm.title,
        pm.production_year,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        ci.kind AS company_type,
        COALESCE(mn.name, 'Unknown') AS director_name
    FROM 
        PopularMovies pm
    LEFT JOIN 
        movie_keyword mk ON pm.title = (SELECT title FROM aka_title WHERE id = pm.title LIMIT 1)
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = (SELECT id FROM aka_title WHERE title = pm.title LIMIT 1)
    LEFT JOIN 
        company_type ci ON mc.company_type_id = ci.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = (SELECT id FROM aka_title WHERE title = pm.title LIMIT 1) 
        AND ci.person_role_id = (SELECT id FROM role_type WHERE role = 'director')
    LEFT JOIN 
        aka_name mn ON ci.person_id = mn.person_id
)
SELECT 
    md.title,
    md.production_year,
    md.keyword,
    md.company_type,
    COUNT(CASE WHEN ci.note IS NULL THEN 1 END) AS uncredited_count
FROM 
    MovieDetails md
LEFT JOIN 
    cast_info ci ON ci.movie_id = (SELECT id FROM aka_title WHERE title = md.title LIMIT 1)
GROUP BY 
    md.title, md.production_year, md.keyword, md.company_type
ORDER BY 
    md.production_year DESC, md.title;
