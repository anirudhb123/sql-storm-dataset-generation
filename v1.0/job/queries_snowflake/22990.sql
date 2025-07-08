
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank_year
    FROM title t
    WHERE t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY a.person_id
    HAVING COUNT(DISTINCT c.movie_id) > 10
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM movie_keyword mkw
    JOIN keyword k ON mkw.keyword_id = k.id
    JOIN aka_title m ON mkw.movie_id = m.id
    WHERE k.keyword IS NOT NULL
    GROUP BY m.id
),
Companies AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, '; ') WITHIN GROUP (ORDER BY cn.name) AS companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    WHERE cn.country_code IS NOT NULL
    GROUP BY mc.movie_id
)
SELECT 
    r.title,
    r.production_year,
    ac.person_id,
    ac.movie_count,
    kw.keywords,
    co.companies,
    CASE 
        WHEN ac.movie_count > 20 THEN 'Prolific Actor'
        WHEN ac.movie_count BETWEEN 11 AND 20 THEN 'Frequent Actor'
        ELSE 'Occasional Actor'
    END AS actor_type,
    COALESCE(NULLIF(ac.movie_count, 0), 1) AS display_count
FROM RankedMovies r
LEFT JOIN ActorCounts ac ON r.title_id = ac.person_id
LEFT JOIN MoviesWithKeywords kw ON r.title_id = kw.movie_id
LEFT JOIN Companies co ON r.title_id = co.movie_id
WHERE 
    r.rank_year <= 5 
    AND (LOWER(kw.keywords) LIKE '%drama%' OR kw.keywords IS NULL)
ORDER BY 
    r.production_year DESC,
    ac.movie_count DESC
LIMIT 10;
