WITH RankedMovies AS (
    SELECT 
        title.title AS movie_title,
        aka_title.production_year,
        COUNT(cast_info.id) AS cast_count,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS actors_list,
        ROW_NUMBER() OVER (PARTITION BY aka_title.production_year ORDER BY COUNT(cast_info.id) DESC) AS rank
    FROM 
        aka_title
    JOIN 
        title ON aka_title.id = title.id
    LEFT JOIN 
        cast_info ON cast_info.movie_id = aka_title.movie_id
    LEFT JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    GROUP BY 
        title.title, aka_title.production_year
),
TitleKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CombinedResults AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.cast_count,
        rm.actors_list,
        tk.keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        TitleKeywords tk ON tk.movie_id = rm.movie_id
)
SELECT 
    movie_title,
    production_year,
    cast_count,
    actors_list,
    keywords
FROM 
    CombinedResults
WHERE 
    rank <= 10
ORDER BY 
    production_year DESC, 
    cast_count DESC;
