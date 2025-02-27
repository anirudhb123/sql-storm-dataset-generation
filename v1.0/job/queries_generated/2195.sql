WITH MovieDetails AS (
    SELECT 
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY k.keyword) AS keyword_rank
    FROM aka_title a
    JOIN movie_keyword mk ON a.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE a.production_year BETWEEN 1990 AND 2023
),
TopMovies AS (
    SELECT 
        md.title,
        md.production_year,
        COUNT(*) AS keyword_count
    FROM MovieDetails md
    WHERE md.keyword_rank <= 3
    GROUP BY md.title, md.production_year
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        r.role AS role_type,
        COUNT(DISTINCT ci.person_id) AS num_actors
    FROM cast_info ci
    JOIN role_type r ON ci.role_id = r.id
    GROUP BY ci.movie_id, r.role
)
SELECT 
    tm.title,
    tm.production_year,
    tm.keyword_count,
    cm.company_name,
    cm.company_type,
    COALESCE(cr.num_actors, 0) AS total_actors,
    CASE 
        WHEN tm.keyword_count > 5 THEN 'Popular'
        ELSE 'Less Popular'
    END AS popularity_rating
FROM TopMovies tm
LEFT JOIN CompanyMovies cm ON tm.title = cm.movie_id
LEFT JOIN CastRoles cr ON tm.title = cr.movie_id
WHERE 
    (tm.keyword_count > 2 OR cr.num_actors > 5)
ORDER BY 
    tm.production_year DESC, tm.keyword_count DESC;
