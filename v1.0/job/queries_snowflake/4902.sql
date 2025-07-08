
WITH RecentMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year >= 2020
    GROUP BY 
        t.id, t.title, t.production_year
),
TopActors AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT cc.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    JOIN 
        complete_cast cc ON c.movie_id = cc.movie_id
    GROUP BY 
        ak.name
    ORDER BY 
        movie_count DESC
    LIMIT 10
),
CompanyInfo AS (
    SELECT 
        mc.movie_id, 
        cn.name AS company_name,
        cty.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type cty ON mc.company_type_id = cty.id
)
SELECT 
    rm.title,
    rm.production_year, 
    COALESCE(ta.actor_name, 'Unknown Actor') AS actor_name,
    rm.cast_count, 
    ci.company_name,
    ci.company_type
FROM 
    RecentMovies rm
LEFT JOIN 
    TopActors ta ON EXISTS (
        SELECT 1
        FROM cast_info c
        WHERE c.movie_id = rm.movie_id AND c.person_id IN (SELECT person_id FROM aka_name WHERE name = ta.actor_name)
    )
LEFT JOIN 
    CompanyInfo ci ON rm.movie_id = ci.movie_id
WHERE 
    rm.cast_count > 5
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;
