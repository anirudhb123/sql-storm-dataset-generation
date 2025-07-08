WITH MovieDetails AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        a.name AS actor_name,
        p.gender,
        COUNT(DISTINCT mc.company_id) AS production_companies,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rn
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        name p ON a.person_id = p.imdb_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = mt.id
    WHERE 
        mt.production_year IS NOT NULL
        AND p.gender IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year, a.name, p.gender
),
TopMovies AS (
    SELECT 
        movie_title, 
        production_year,
        actor_name, 
        gender, 
        production_companies
    FROM 
        MovieDetails
    WHERE 
        rn = 1
)
SELECT 
    tm.movie_title,
    tm.production_year,
    COALESCE(tm.actor_name, 'Unknown') AS actor_name,
    (SELECT COUNT(*) FROM movie_keyword mk JOIN keyword k ON mk.keyword_id = k.id WHERE mk.movie_id = (SELECT id FROM aka_title WHERE title = tm.movie_title LIMIT 1)) AS keyword_count,
    CASE 
        WHEN tm.production_companies > 1 THEN 'Multiple'
        WHEN tm.production_companies = 1 THEN 'Single'
        ELSE 'None'
    END AS company_count_desc
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC, 
    tm.movie_title;
