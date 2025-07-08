
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieCast AS (
    SELECT 
        c.movie_id, 
        p.name, 
        COUNT(*) AS actor_count
    FROM 
        cast_info c
    JOIN 
        name p ON c.person_id = p.id
    GROUP BY 
        c.movie_id, p.name
),
MoviesWithKeywords AS (
    SELECT 
        m.movie_id, 
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.name) AS company_count,
        MAX(c.name) AS last_company_name  
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.title_id, 
    tm.title, 
    tm.production_year, 
    mc.actor_count, 
    mk.keywords, 
    cm.company_count, 
    cm.last_company_name
FROM 
    RankedMovies tm
LEFT JOIN 
    MovieCast mc ON tm.title_id = mc.movie_id
LEFT JOIN 
    MoviesWithKeywords mk ON tm.title_id = mk.movie_id
LEFT JOIN 
    CompanyMovies cm ON tm.title_id = cm.movie_id
WHERE 
    (mc.actor_count IS NULL OR mc.actor_count >= 5)  
AND 
    (tm.rank_per_year <= 3)  
ORDER BY 
    tm.production_year DESC,
    tm.title ASC
LIMIT 10;
