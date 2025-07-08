
WITH MovieActors AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        a.name AS actor_name, 
        a.id AS actor_id, 
        RANK() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS actor_rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
),
TopMovies AS (
    SELECT 
        ma.movie_id, 
        ma.title, 
        LISTAGG(ma.actor_name, ', ') WITHIN GROUP (ORDER BY ma.actor_rank) AS actor_list
    FROM 
        MovieActors ma
    WHERE 
        ma.actor_rank <= 3
    GROUP BY 
        ma.movie_id, ma.title
),
CompanyDetails AS (
    SELECT 
        mc.movie_id, 
        cn.name AS company_name, 
        ct.kind AS company_type
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    tm.title, 
    tm.actor_list, 
    COALESCE(cd.company_name, 'Independent') AS production_company, 
    COUNT(DISTINCT cd.company_type) AS num_company_types
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyDetails cd ON tm.movie_id = cd.movie_id
GROUP BY 
    tm.title, tm.actor_list, cd.company_name
HAVING 
    COUNT(*) > 1 AND COUNT(DISTINCT cd.company_type) > 1
ORDER BY 
    tm.title ASC;
