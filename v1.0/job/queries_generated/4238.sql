WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY RAND()) AS rank
    FROM title t
    WHERE t.production_year IS NOT NULL
), 
MovieCast AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        role.role AS role_name,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN role_type role ON ci.role_id = role.id
), 
TopMovies AS (
    SELECT 
        mv.id AS movie_id,
        mv.title,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COALESCE(SUM(mi.info IS NOT NULL AND mi.info <> ''), 0) AS info_entries
    FROM 
        RankedTitles mv
    LEFT JOIN 
        movie_companies mc ON mv.id = mc.movie_id
    LEFT JOIN 
        movie_info mi ON mv.id = mi.movie_id
    GROUP BY 
        mv.id
    HAVING 
        COUNT(DISTINCT mc.company_id) > 1
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    mc.actor_name,
    mc.role_name,
    tm.company_count,
    tm.info_entries,
    nt.keyword AS movie_keyword
FROM 
    TopMovies tm
LEFT JOIN 
    MovieCast mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword nt ON mk.keyword_id = nt.id
WHERE 
    mc.role_rank = 1 
    AND tm.company_count IS NOT NULL
ORDER BY 
    tm.production_year DESC, 
    tm.title ASC;
