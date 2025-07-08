
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS year_rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        r.title,
        r.production_year,
        r.actor_count
    FROM 
        RankedMovies r
    WHERE 
        r.year_rank <= 5
),
MovieDetails AS (
    SELECT 
        t.title,
        COALESCE(mg.name, 'Unknown') AS genre,
        t.production_year,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre')
    LEFT JOIN 
        company_name mg ON mg.id = (SELECT company_id 
                                     FROM movie_companies 
                                     WHERE movie_id = t.id 
                                     ORDER BY company_id LIMIT 1)
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IN (SELECT DISTINCT production_year FROM TopMovies)
    GROUP BY 
        t.title, t.production_year, mg.name
)
SELECT 
    m.title,
    m.production_year,
    m.genre,
    m.keywords,
    (SELECT COUNT(*) 
     FROM complete_cast cc 
     WHERE cc.movie_id = (SELECT id FROM aka_title WHERE title = m.title LIMIT 1)) AS complete_cast_count
FROM 
    MovieDetails m
ORDER BY 
    m.production_year DESC, m.title;
