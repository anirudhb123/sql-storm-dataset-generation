WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(CASE WHEN p.gender = 'F' THEN 1 ELSE 0 END) AS female_ratio,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        name p ON c.person_id = p.imdb_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        total_cast, 
        female_ratio
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        m.title,
        ARRAY_AGG(k.keyword) AS keywords
    FROM 
        TopMovies m
    LEFT JOIN 
        movie_keyword mk ON m.title = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.title
)
SELECT 
    tm.title,
    tm.production_year,
    tm.total_cast,
    tm.female_ratio,
    COALESCE(mk.keywords, '{}') AS keywords,
    CASE 
        WHEN tm.female_ratio > 0.5 THEN 'Predominantly Female'
        ELSE 'Not Predominantly Female'
    END AS cast_gender_domination
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.title = mk.title
ORDER BY 
    tm.production_year DESC, 
    tm.total_cast DESC;
