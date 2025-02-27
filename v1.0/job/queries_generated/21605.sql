WITH movie_years AS (
    SELECT 
        production_year,
        COUNT(*) AS movie_count,
        AVG(production_year) OVER () AS avg_production_year
    FROM 
        aka_title 
    GROUP BY 
        production_year
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
filtered_movies AS (
    SELECT 
        at.title,
        at.production_year,
        cs.total_cast,
        ks.keywords,
        ym.movie_count,
        yn.movie_count AS year_movies
    FROM 
        aka_title at
    LEFT JOIN 
        cast_summary cs ON at.id = cs.movie_id
    LEFT JOIN 
        keyword_summary ks ON at.id = ks.movie_id
    JOIN 
        movie_years ym ON at.production_year = ym.production_year 
    JOIN 
        (SELECT 
            production_year, 
            COUNT(*) AS movie_count 
         FROM 
            aka_title 
         WHERE
            production_year IS NOT NULL 
         GROUP BY 
            production_year
         HAVING 
            COUNT(*) > (SELECT AVG(movie_count) FROM movie_years)
        ) yn ON at.production_year = yn.production_year
    WHERE 
        at.production_year IS NOT NULL
)
SELECT 
    f.title,
    f.production_year,
    COALESCE(f.total_cast, 0) AS total_cast,
    COALESCE(f.keywords, 'No keywords') AS keywords,
    f.movie_count AS movies_in_year,
    CASE 
        WHEN f.production_year < (SELECT AVG(production_year) FROM movie_years) THEN 'Older than average' 
        ELSE 'Newer than average' 
    END AS age_comparison
FROM 
    filtered_movies f
ORDER BY 
    f.production_year DESC, 
    f.total_cast DESC
LIMIT 50;
