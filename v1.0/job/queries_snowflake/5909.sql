WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        ak.name AS actor_name, 
        COUNT(ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rnk
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id 
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        cn.country_code = 'USA' 
        AND t.production_year > 2000
    GROUP BY 
        t.id, t.title, t.production_year, ak.name
), FilteredMovies AS (
    SELECT 
        title, 
        production_year, 
        actor_name, 
        actor_count
    FROM 
        RankedMovies
    WHERE 
        rnk = 1 AND actor_count > 5
)
SELECT 
    f.title, 
    f.production_year, 
    f.actor_name 
FROM 
    FilteredMovies f 
ORDER BY 
    f.production_year DESC, 
    f.actor_name;
