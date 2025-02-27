WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        COUNT(c.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year
),
SelectedMovies AS (
    SELECT 
        movie_title,
        production_year,
        aka_names,
        cast_count,
        keywords
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
)
SELECT 
    sm.movie_title,
    sm.production_year,
    sm.aka_names,
    sm.cast_count,
    COALESCE(STRING_AGG(DISTINCT cn.name, ', '), 'No Companies') AS production_companies
FROM 
    SelectedMovies sm
LEFT JOIN 
    movie_companies mc ON mc.movie_id = (
        SELECT id FROM aka_title WHERE title = sm.movie_title LIMIT 1
    )
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
GROUP BY 
    sm.movie_title, sm.production_year, sm.aka_names, sm.cast_count
ORDER BY 
    sm.production_year DESC;
