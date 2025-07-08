WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        complete_cast cc ON cc.movie_id = t.id
    JOIN 
        cast_info ci ON ci.movie_id = t.id
    WHERE 
        cn.country_code = 'USA'
    GROUP BY 
        t.id, t.title, t.production_year
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
),
GenreMovies AS (
    SELECT 
        km.movie_id,
        k.keyword
    FROM 
        movie_keyword km
    JOIN 
        keyword k ON km.keyword_id = k.id
    WHERE 
        k.keyword IN ('Drama', 'Comedy')
),
FinalSelection AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COUNT(DISTINCT gm.keyword) AS genre_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        GenreMovies gm ON rm.movie_id = gm.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
)
SELECT 
    fs.movie_id,
    fs.title,
    fs.production_year,
    fs.genre_count
FROM 
    FinalSelection fs
ORDER BY 
    fs.production_year DESC, fs.genre_count DESC;
