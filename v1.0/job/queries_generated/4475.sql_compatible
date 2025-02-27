
WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    GROUP BY 
        mt.title, mt.production_year
),
HighActorCountMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        actor_count > (SELECT AVG(actor_count) FROM RankedMovies)
),
TopCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    ham.title,
    ham.production_year,
    tc.company_names,
    COALESCE(mk.keywords, 'No Keywords') AS keywords
FROM 
    HighActorCountMovies ham
LEFT JOIN 
    TopCompanies tc ON tc.movie_id = (SELECT id FROM aka_title WHERE title = ham.title LIMIT 1)
LEFT JOIN 
    (SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id) mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = ham.title LIMIT 1)
WHERE 
    ham.production_year IS NOT NULL
ORDER BY 
    ham.production_year DESC, ham.title;
