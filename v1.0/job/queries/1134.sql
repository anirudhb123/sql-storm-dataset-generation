WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS num_cast_members,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.title, at.production_year
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.num_cast_members
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
MovieKeywords AS (
    SELECT 
        mt.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords 
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN tm.num_cast_members > 10 THEN 'Large Cast'
        WHEN tm.num_cast_members > 5 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category,
    (SELECT COUNT(DISTINCT mci.company_id)
     FROM movie_companies mci
     WHERE mci.movie_id = (SELECT mt.movie_id FROM aka_title mt WHERE mt.title = tm.title LIMIT 1)
    ) AS num_companies
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = tm.title LIMIT 1)
ORDER BY 
    tm.production_year DESC, tm.num_cast_members DESC;
