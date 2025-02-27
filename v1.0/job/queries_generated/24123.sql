WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM aka_title t
    WHERE t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Movie%')
), 
MovieCast AS (
    SELECT 
        mc.movie_id, 
        COUNT(DISTINCT ci.person_id) AS cast_count 
    FROM complete_cast mc
    JOIN cast_info ci ON mc.movie_id = ci.movie_id
    GROUP BY mc.movie_id
), 
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        CASE 
            WHEN ct.kind IS NULL THEN 'Unknown'
            ELSE ct.kind
        END AS resolved_company_type
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
), 
KeyWordStats AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords 
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(mb.cast_count, 0) AS total_cast,
    cm.company_name,
    cm.resolved_company_type,
    k.keyword AS movie_keywords, 
    rk.rn, 
    rk.total_movies,
    CASE 
        WHEN m.production_year > 2000 THEN 'Modern Era'
        WHEN m.production_year BETWEEN 1980 AND 2000 THEN 'Late 20th Century'
        ELSE 'Classic'
    END AS era
FROM RankedMovies rm
LEFT JOIN MovieCast mb ON rm.movie_id = mb.movie_id
LEFT JOIN CompanyMovies cm ON rm.movie_id = cm.movie_id
LEFT JOIN KeyWordStats k ON rm.movie_id = k.movie_id
JOIN aka_name an ON an.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = rm.movie_id)
WHERE 
    rm.production_year IS NOT NULL
    AND rm.title IS NOT NULL
ORDER BY 
    rm.production_year DESC,
    total_cast DESC,
    rm.title
LIMIT 50;
