WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        GREATEST(
            COALESCE(MAX(m.production_year), 0),
            COALESCE(MAX(mt.production_year), 0)
        ) AS latest_production_year
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        aka_title at ON t.id = at.movie_id
    LEFT JOIN 
        aka_name an ON an.person_id = ci.person_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    LEFT JOIN 
        kind_type kt ON t.kind_id = kt.id
    LEFT JOIN 
        (SELECT DISTINCT movie_id, MAX(production_year) AS production_year 
         FROM title 
         GROUP BY movie_id) m ON t.id = m.movie_id
    LEFT JOIN 
        (SELECT DISTINCT movie_id, MAX(production_year) AS production_year 
         FROM aka_title 
         GROUP BY movie_id) mt ON t.id = mt.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), FilteredMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        actor_count, 
        latest_production_year
    FROM 
        RankedMovies 
    WHERE 
        actor_count > 5 AND 
        production_year BETWEEN 2000 AND 2023
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.actor_count,
    f.latest_production_year,
    CONCAT('The movie "', f.title, '" (', f.production_year, ') features ', f.actor_count, ' actors.') AS description
FROM 
    FilteredMovies f
ORDER BY 
    f.latest_production_year DESC, 
    f.actor_count DESC
LIMIT 10;
