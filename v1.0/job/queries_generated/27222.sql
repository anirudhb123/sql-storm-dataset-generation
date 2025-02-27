WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        title t
    JOIN 
        aka_title at ON at.movie_id = t.id
    JOIN 
        cast_info c ON c.movie_id = at.movie_id
    JOIN 
        aka_name ak ON ak.person_id = c.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
), 

FilteredMovies AS (
    SELECT
        movie_title,
        production_year,
        cast_count,
        aka_names
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
)

SELECT 
    f.movie_title,
    f.production_year,
    f.cast_count,
    STRING_AGG(DISTINCT f.aka_names[1], ', ') AS prominent_names,
    STRING_AGG(DISTINCT n.gender, ', ') AS gender_distribution,
    (SELECT COUNT(DISTINCT k.keyword) 
     FROM movie_keyword mk 
     JOIN keyword k ON k.id = mk.keyword_id 
     WHERE mk.movie_id = (SELECT at.movie_id FROM aka_title at WHERE at.title = f.movie_title LIMIT 1)
    ) AS keyword_count
FROM 
    FilteredMovies f
LEFT JOIN 
    cast_info c ON c.movie_id IN (SELECT at.movie_id FROM aka_title at WHERE at.title = f.movie_title)
LEFT JOIN 
    name n ON n.id = c.person_id
GROUP BY 
    f.movie_title, f.production_year, f.cast_count
ORDER BY 
    f.production_year DESC, f.cast_count DESC;
