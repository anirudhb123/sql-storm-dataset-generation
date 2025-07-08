
WITH RECURSIVE ActorMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY a.id ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
SubqueryActors AS (
    SELECT 
        actor_id,
        actor_name,
        COUNT(movie_id) AS movie_count
    FROM 
        ActorMovies
    GROUP BY 
        actor_id, actor_name
    HAVING 
        COUNT(movie_id) > 5
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER(PARTITION BY mc.movie_id ORDER BY cn.name) as company_seq
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
FilteredMovies AS (
    SELECT 
        am.actor_id,
        am.actor_name,
        am.movie_id,
        am.title,
        am.production_year,
        cd.company_name,
        cd.company_type
    FROM 
        ActorMovies am
    LEFT JOIN 
        CompanyDetails cd ON am.movie_id = cd.movie_id
    WHERE 
        am.movie_rank <= 3
)
SELECT 
    f.actor_id,
    f.actor_name,
    f.title,
    f.production_year,
    COUNT(DISTINCT f.company_name) AS company_count,
    LISTAGG(DISTINCT f.company_type, ', ') WITHIN GROUP (ORDER BY f.company_type) AS company_types,
    SUM(CASE WHEN f.production_year < 2000 THEN 1 ELSE 0 END) AS pre_2000_movies,
    CASE 
        WHEN COUNT(DISTINCT f.title) > 10 THEN 'Prolific Actor'
        ELSE 'Emerging Actor'
    END AS actor_status
FROM 
    FilteredMovies f
GROUP BY 
    f.actor_id,
    f.actor_name,
    f.title,
    f.production_year
ORDER BY 
    company_count DESC, f.actor_name;
