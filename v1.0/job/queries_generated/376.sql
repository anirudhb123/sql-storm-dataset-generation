WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.title, 
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn <= 5
),
MovieDetails AS (
    SELECT 
        tm.title,
        GROUP_CONCAT(DISTINCT ak.name) AS actor_names,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = (SELECT id FROM aka_title WHERE title = tm.title)
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        tm.title
)
SELECT 
    md.title,
    md.actor_names,
    md.company_names,
    COALESCE((SELECT COUNT(*)
               FROM movie_info mi
               WHERE mi.movie_id = (SELECT id FROM aka_title WHERE title = md.title)
               AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'rating')), 0) AS rating_count
FROM 
    MovieDetails md
ORDER BY 
    md.title;
