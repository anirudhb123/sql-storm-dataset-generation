WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE k.keyword LIKE '%action%'
),

DetailedCast AS (
    SELECT 
        c.movie_id, 
        a.name AS actor_name, 
        r.role AS role_name, 
        co.name AS company_name,
        COUNT(DISTINCT cm.id) AS company_count
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type r ON c.role_id = r.id
    JOIN movie_companies mc ON c.movie_id = mc.movie_id
    JOIN company_name co ON mc.company_id = co.id
    GROUP BY c.movie_id, a.name, r.role, co.name
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    dc.actor_name,
    dc.role_name,
    dc.company_name,
    dc.company_count
FROM RankedMovies rm
JOIN DetailedCast dc ON rm.movie_id = dc.movie_id
WHERE rm.rank <= 5
ORDER BY rm.production_year DESC, rm.title;
