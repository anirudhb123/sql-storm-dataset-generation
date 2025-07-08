
WITH RankedMovies AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS num_cast_members,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.title, at.production_year
),
TopMovies AS (
    SELECT 
        movie_title, 
        production_year, 
        num_cast_members 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 10
),
MovieDetails AS (
    SELECT 
        tm.movie_title,
        tm.production_year,
        LISTAGG(aka.name, ', ') AS main_actors,
        MAX(mi.info) AS rating
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = (SELECT movie_id FROM aka_title WHERE title = tm.movie_title LIMIT 1)
    LEFT JOIN 
        aka_name aka ON aka.person_id = mc.company_id 
    LEFT JOIN 
        movie_info mi ON tm.production_year = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
    GROUP BY 
        tm.movie_title, tm.production_year
)
SELECT 
    md.movie_title,
    md.production_year,
    md.main_actors,
    COALESCE(md.rating, 'No Rating') AS movie_rating
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, md.movie_title;
