WITH RankedTitles AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorTitles AS (
    SELECT 
        a.id AS actor_id, 
        a.name AS actor_name, 
        r.title, 
        r.production_year, 
        COALESCE(c.nr_order, 0) AS order_nr
    FROM 
        akka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        ranked_titles r ON c.movie_id = r.title_id
),
CompanyFilms AS (
    SELECT 
        mc.movie_id, 
        cn.name AS company_name, 
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        cn.country_code = 'USA'
),
FilteredActors AS (
    SELECT 
        actor_id, 
        actor_name, 
        COUNT(*) AS total_films
    FROM 
        ActorTitles
    GROUP BY 
        actor_id, 
        actor_name
    HAVING 
        COUNT(*) > 3
)
SELECT 
    fa.actor_name, 
    ft.title, 
    ft.production_year, 
    cf.company_name, 
    cf.company_type
FROM 
    FilteredActors fa
JOIN 
    ActorTitles ft ON fa.actor_id = ft.actor_id
LEFT JOIN 
    CompanyFilms cf ON ft.title = cf.movie_id
ORDER BY 
    fa.actor_name, 
    ft.production_year DESC
LIMIT 50;
