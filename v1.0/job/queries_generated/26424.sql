WITH MovieData AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name SEPARATOR ', ') AS aka_names,
        COUNT(DISTINCT c.person_id) AS cast_count,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
),
MostPopularMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        aka_names,
        cast_count,
        keywords,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        MovieData
    WHERE 
        cast_count > 0
)
SELECT 
    mp.movie_id,
    mp.title,
    mp.production_year,
    mp.aka_names,
    mp.cast_count,
    mp.keywords
FROM 
    MostPopularMovies mp
WHERE 
    mp.rank <= 10
ORDER BY 
    mp.production_year DESC, 
    mp.cast_count DESC;
