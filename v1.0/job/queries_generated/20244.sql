WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
), 
TopMovies AS (
    SELECT 
        movie_id, title, production_year
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast = 1
), 
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COALESCE(mi.info, 'No Info') AS movie_info
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON tm.movie_id = mi.movie_id
    GROUP BY 
        tm.title, tm.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.actor_names,
    md.keywords,
    md.movie_info,
    CASE 
        WHEN md.production_year IS NULL THEN 'Year Not Available'
        WHEN md.production_year < 2000 THEN 'Old Movie'
        ELSE 'Recent Movie'
    END AS movie_age_category
FROM 
    MovieDetails md
WHERE 
    EXISTS (
        SELECT 1
        FROM company_name cn
        JOIN movie_companies mc ON cn.id = mc.company_id
        WHERE mc.movie_id = md.movie_id AND cn.country_code = 'US'
    ) 
    AND md.keywords IS NOT NULL
ORDER BY 
    md.production_year DESC, md.title;
