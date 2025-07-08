
WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.company_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
ActorDetails AS (
    SELECT 
        ak.name AS actor_name,
        mt.title,
        mt.production_year,
        ci.nr_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        aka_title mt ON ci.movie_id = mt.id
)

SELECT 
    tm.title,
    tm.production_year,
    LISTAGG(DISTINCT ad.actor_name, ', ') WITHIN GROUP (ORDER BY ad.actor_name) AS actors,
    tm.company_count,
    CASE 
        WHEN tm.company_count > 3 THEN 'High Production'
        WHEN tm.company_count IS NULL THEN 'Unknown Production'
        ELSE 'Moderate Production'
    END AS production_category
FROM 
    TopMovies tm
LEFT JOIN 
    ActorDetails ad ON tm.title = ad.title AND tm.production_year = ad.production_year
GROUP BY 
    tm.title, tm.production_year, tm.company_count
ORDER BY 
    tm.production_year DESC, tm.company_count DESC;
