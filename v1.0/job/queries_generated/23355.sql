WITH RecursiveRoleCounts AS (
    SELECT 
        ci.person_id,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ci.person_id
),
MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COALESCE(MAX(cn.name), 'Unknown') AS company_name,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    GROUP BY 
        t.id
),
PopularMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_count,
        rn.role_count,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.cast_count DESC) AS popularity_rank
    FROM 
        MovieDetails md
    JOIN 
        RecursiveRoleCounts rn ON md.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = rn.person_id)
    WHERE 
        md.production_year IS NOT NULL
)
SELECT 
    pm.title AS movie_title,
    pm.production_year,
    pm.cast_count,
    pm.role_count,
    CASE 
        WHEN pm.cast_count IS NULL THEN 'No Cast'
        ELSE CONCAT('Cast Count: ', pm.cast_count)
    END AS cast_info,
    COALESCE(NULLIF(pm.company_name, 'Unknown'), 'No Company Info') AS company_info,
    SUM(CASE WHEN pm.popularity_rank <= 5 THEN 1 ELSE 0 END) OVER () AS top_5_movies_count
FROM 
    PopularMovies pm
WHERE 
    EXISTS (
        SELECT 1 FROM movie_keyword mk 
        WHERE mk.movie_id = pm.movie_id AND mk.keyword_id IN 
        (SELECT id FROM keyword WHERE keyword LIKE '%Thriller%')
    )
    OR 
    pm.production_year > (SELECT AVG(production_year) FROM aka_title)
ORDER BY 
    pm.production_year DESC, 
    pm.popularity_rank
FETCH FIRST 10 ROWS ONLY;
