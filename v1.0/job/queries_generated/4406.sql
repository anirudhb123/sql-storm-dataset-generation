WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS num_cast_members,
        DENSE_RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.num_cast_members
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_by_cast = 1
),
MovieKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.num_cast_members,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN tm.num_cast_members > 50 THEN 'Large Cast'
        WHEN tm.num_cast_members BETWEEN 21 AND 50 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.title = mk.movie_id
WHERE 
    tm.production_year BETWEEN 2000 AND 2020
ORDER BY 
    tm.production_year DESC, tm.num_cast_members DESC;
