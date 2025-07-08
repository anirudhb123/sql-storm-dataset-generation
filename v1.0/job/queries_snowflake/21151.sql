
WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank 
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.title, 
        t.production_year
),
HighCastMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
),
ActorTitles AS (
    SELECT 
        ak.name AS actor_name,
        t.title AS movie_title,
        t.production_year
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
),
CompanyMovieTitles AS (
    SELECT 
        cn.name AS company_name,
        t.title AS movie_title,
        t.production_year
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        aka_title t ON mc.movie_id = t.id
    WHERE 
        cn.country_code IS NOT NULL
)
SELECT 
    ht.production_year,
    COUNT(DISTINCT at.actor_name) AS actor_count,
    COUNT(DISTINCT cmt.company_name) AS company_count,
    LISTAGG(DISTINCT at.movie_title, '; ') WITHIN GROUP (ORDER BY at.movie_title) AS movie_titles,
    LISTAGG(DISTINCT cmt.movie_title, '; ') WITHIN GROUP (ORDER BY cmt.movie_title) AS produced_movies
FROM 
    HighCastMovies ht
LEFT JOIN 
    ActorTitles at ON ht.title = at.movie_title AND ht.production_year = at.production_year
FULL OUTER JOIN 
    CompanyMovieTitles cmt ON ht.title = cmt.movie_title AND ht.production_year = cmt.production_year
GROUP BY 
    ht.production_year
HAVING 
    COUNT(DISTINCT at.actor_name) > 3 OR COUNT(DISTINCT cmt.company_name) > 1
ORDER BY 
    ht.production_year DESC;
