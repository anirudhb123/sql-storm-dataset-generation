
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank,
        COUNT(cm.company_id) AS company_count
    FROM 
        aka_title t
    LEFT JOIN movie_companies cm ON t.id = cm.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.company_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.year_rank <= 5
),
ActorDetails AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        LISTAGG(DISTINCT t.title, ', ') WITHIN GROUP (ORDER BY t.title) AS movies
    FROM 
        aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN aka_title t ON ci.movie_id = t.id
    GROUP BY 
        a.person_id, a.name
)
SELECT 
    td.title AS Movie_Title,
    td.production_year AS Production_Year,
    ad.name AS Actor_Name,
    ad.movie_count AS Total_Movies,
    ad.movies AS Movies_List
FROM 
    TopMovies td
LEFT JOIN ActorDetails ad ON ad.person_id IN (SELECT person_id FROM cast_info WHERE movie_id = td.movie_id)
WHERE 
    td.company_count > 2
ORDER BY 
    td.production_year DESC, ad.movie_count DESC;
