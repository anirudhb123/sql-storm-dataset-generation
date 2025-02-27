WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY YEAR(t.production_year) ORDER BY COUNT(ci.person_id) DESC) AS role_rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    GROUP BY 
        t.title, t.production_year
),
RecentMovies AS (
    SELECT 
        title, 
        production_year
    FROM 
        RankedMovies
    WHERE 
        role_rank <= 5
),
CastDetails AS (
    SELECT 
        a.name AS actor_name,
        t.title,
        ci.nr_order,
        ct.kind AS role_type,
        cmp.name AS company_name
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    JOIN 
        movie_companies mc ON mc.movie_id = t.movie_id
    JOIN 
        company_name cmp ON mc.company_id = cmp.id
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
)
SELECT 
    rd.production_year,
    STRING_AGG(DISTINCT cd.actor_name, ', ') AS actors,
    STRING_AGG(DISTINCT cd.title, ', ') AS movie_titles,
    COUNT(DISTINCT cd.company_name) AS unique_companies
FROM 
    RecentMovies rd
LEFT JOIN 
    CastDetails cd ON rd.title = cd.title AND rd.production_year = cd.production_year
GROUP BY 
    rd.production_year
ORDER BY 
    rd.production_year DESC;
