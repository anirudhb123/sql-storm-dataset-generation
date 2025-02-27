WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM title t
    JOIN aka_title at ON t.id = at.movie_id
    WHERE t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role,
        c.nr_order
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type r ON c.role_id = r.id
),
CompanyMovieInfo AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name co ON mc.company_id = co.id
    JOIN company_type ct ON mc.company_type_id = ct.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    ARRAY_AGG(DISTINCT ar.actor_name ORDER BY ar.nr_order) AS actors,
    ARRAY_AGG(DISTINCT cm.company_name) AS companies,
    ARRAY_AGG(DISTINCT mk.keyword) AS keywords
FROM RankedMovies rm
LEFT JOIN ActorRoles ar ON rm.movie_id = ar.movie_id
LEFT JOIN CompanyMovieInfo cm ON rm.movie_id = cm.movie_id
LEFT JOIN MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE rm.title_rank <= 10
GROUP BY rm.movie_id, rm.title, rm.production_year
ORDER BY rm.production_year DESC, rm.title;
