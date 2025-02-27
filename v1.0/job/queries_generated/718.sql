WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS num_cast_members,
        ARRAY_AGG(DISTINCT an.name ORDER BY an.name) AS cast_names,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS year_rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.id, at.title, at.production_year
),
MoviesWithInfo AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.num_cast_members,
        rm.cast_names,
        mi.info AS additional_info
    FROM
        RankedMovies rm
    LEFT JOIN 
        movie_info mi ON rm.production_year = mi.movie_id
    WHERE 
        rm.year_rank <= 5
)

SELECT 
    m.title,
    m.production_year,
    m.num_cast_members,
    COALESCE(m.additional_info, 'No Info Available') AS info,
    STRING_AGG(DISTINCT m.cast_names::text, ', ') AS full_cast_list
FROM 
    MoviesWithInfo m
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = m.title LIMIT 1)
WHERE 
    m.num_cast_members > 5
GROUP BY 
    m.title, m.production_year, m.num_cast_members, m.additional_info
ORDER BY 
    m.production_year DESC, m.num_cast_members DESC;
