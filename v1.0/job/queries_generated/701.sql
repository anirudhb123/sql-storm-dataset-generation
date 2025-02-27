WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT cc.person_id) AS total_cast
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),

DirectorInfo AS (
    SELECT 
        c.movie_id,
        COALESCE(a.name, 'Unknown') AS director_name
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.person_role_id = (SELECT id FROM role_type WHERE role = 'Director')
),

YearlyProduction AS (
    SELECT 
        production_year,
        COUNT(*) AS movie_count
    FROM 
        aka_title
    GROUP BY 
        production_year
)

SELECT 
    md.movie_title,
    md.production_year,
    di.director_name,
    md.keywords,
    md.total_cast,
    yp.movie_count,
    ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.total_cast DESC) AS cast_rank
FROM 
    MovieDetails md
LEFT JOIN 
    DirectorInfo di ON md.movie_title = (SELECT title FROM aka_title WHERE id = di.movie_id)
LEFT JOIN 
    YearlyProduction yp ON md.production_year = yp.production_year
WHERE 
    (md.production_year IS NOT NULL)
    AND (md.total_cast > 1 OR md.keywords IS NOT NULL)
ORDER BY 
    md.production_year DESC, 
    md.total_cast DESC;
