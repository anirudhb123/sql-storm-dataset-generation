WITH RankedMovies AS (
    SELECT 
        a.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY at.production_year DESC) AS rank,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM title a
    JOIN aka_title at ON a.id = at.movie_id
    LEFT JOIN cast_info c ON at.movie_id = c.movie_id
    GROUP BY a.id, a.title, at.production_year
),
RecentMovies AS (
    SELECT 
        r.title,
        r.production_year,
        r.actor_count,
        CASE 
            WHEN r.actor_count > 5 THEN 'Blockbuster'
            WHEN r.actor_count BETWEEN 3 AND 5 THEN 'Moderate'
            ELSE 'Indie'
        END AS movie_category
    FROM RankedMovies r
    WHERE r.rank = 1
),
MovieInfo AS (
    SELECT 
        m.title,
        m.production_year,
        COALESCE(mi.info, 'No Info') AS movie_info,
        m.movie_category
    FROM RecentMovies m
    LEFT JOIN movie_info mi ON m.title = mi.info
)

SELECT 
    m.title,
    m.production_year,
    m.movie_info,
    m.movie_category,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT mp.company_id) AS company_count
FROM MovieInfo m
LEFT JOIN movie_keyword mk ON m.title = mk.movie_id 
LEFT JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN movie_companies mp ON m.title = mp.movie_id
WHERE m.production_year IS NOT NULL 
GROUP BY m.title, m.production_year, m.movie_info, m.movie_category
HAVING COUNT(DISTINCT mp.company_id) > 0
ORDER BY m.production_year DESC, m.title;
