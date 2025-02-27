WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS role_rank
    FROM title t
    LEFT JOIN cast_info c ON t.id = c.movie_id
    GROUP BY t.id, t.title, t.production_year
),
AllCast AS (
    SELECT 
        c.id AS cast_id,
        p.name AS person_name,
        t.title AS movie_title,
        COALESCE(mk.keyword, 'No Keyword') AS keyword,
        t.production_year
    FROM cast_info c
    INNER JOIN aka_name p ON c.person_id = p.person_id
    INNER JOIN title t ON c.movie_id = t.id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    WHERE p.name IS NOT NULL
),
MovieCompanies AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    INNER JOIN complete_cast m ON mc.movie_id = m.movie_id
    GROUP BY m.movie_id
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    ac.person_name,
    ac.keyword,
    m.company_count,
    CASE 
        WHEN m.company_count > 0 THEN 'Produced'
        ELSE 'Not Produced' 
    END AS production_status,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = r.movie_id) AS info_count
FROM RankedMovies r
JOIN AllCast ac ON r.movie_id = ac.movie_id
JOIN MovieCompanies m ON r.movie_id = m.movie_id
WHERE r.role_rank <= 5
ORDER BY r.production_year, r.title;
