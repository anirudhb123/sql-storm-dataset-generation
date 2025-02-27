WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        t.kind_id, 
        ak.name AS alias_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY ak.name) AS rn
    FROM 
        aka_title ak_t
    JOIN 
        aka_name ak ON ak_t.title = ak.name
    JOIN 
        title t ON ak_t.movie_id = t.id
    WHERE 
        t.production_year >= 2000
), MovieCast AS (
    SELECT 
        rc.movie_id,
        rc.title,
        rc.production_year,
        c.person_id,
        p.name AS actor_name,
        rc.alias_name
    FROM 
        RankedMovies rc
    JOIN 
        cast_info c ON rc.movie_id = c.movie_id
    JOIN 
        name p ON c.person_id = p.imdb_id
    WHERE 
        c.role_id IN (SELECT id FROM role_type WHERE role ILIKE '%actor%')
), CompanyMovies AS (
    SELECT 
        mc.movie_id, 
        m.name AS company_name, 
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name m ON mc.company_id = m.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    mc.movie_id, 
    mc.title, 
    mc.production_year, 
    STRING_AGG(DISTINCT c.actor_name, ', ') AS actors,
    STRING_AGG(DISTINCT cm.company_name || ' (' || cm.company_type || ')', '; ') AS companies,
    COUNT(DISTINCT c.actor_name) AS actor_count,
    COUNT(DISTINCT cm.company_name) AS company_count,
    MIN(cam.alias_name) AS first_alias,
    MAX(cam.alias_name) AS last_alias
FROM 
    MovieCast c
JOIN 
    CompanyMovies cm ON c.movie_id = cm.movie_id
JOIN 
    RankedMovies cam ON c.movie_id = cam.movie_id
GROUP BY 
    mc.movie_id, mc.title, mc.production_year
ORDER BY 
    mc.production_year DESC, mc.movie_id;
