WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN 
        cast_info c ON c.movie_id = t.id
    LEFT JOIN 
        aka_name ak ON ak.person_id = c.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),

FilteredMovies AS (
    SELECT 
        title,
        production_year,
        aka_names,
        cast_count 
    FROM 
        RankedMovies
    WHERE 
        cast_count > 0
)

SELECT 
    CAST(FM.production_year AS VARCHAR) AS Year,
    FM.title AS Movie_Title,
    FM.aka_names AS Alternate_Names,
    FM.cast_count AS Number_of_Cast
FROM 
    FilteredMovies FM
WHERE 
    FM.year_rank <= 5
ORDER BY 
    FM.production_year DESC, FM.cast_count DESC;
