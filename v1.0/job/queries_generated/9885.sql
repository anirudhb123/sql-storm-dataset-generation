WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        AVG(CASE WHEN p.gender = 'F' THEN 1 ELSE 0 END) AS female_cast_ratio
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        name p ON a.person_id = p.imdb_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        female_cast_ratio,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)

SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.female_cast_ratio,
    GROUP_CONCAT(DISTINCT cn.name) AS company_names,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.cast_count, tm.female_cast_ratio
ORDER BY 
    tm.cast_count DESC;
