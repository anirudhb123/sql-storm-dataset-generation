WITH MovieOverview AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS note_present,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_actor_count
    FROM title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    GROUP BY t.id, t.title, t.production_year, k.keyword
),
TopMovies AS (
    SELECT 
        title_id,
        title,
        production_year,
        actor_count,
        note_present
    FROM MovieOverview
    WHERE rank_by_actor_count <= 5
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.id) AS company_count
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id, c.name, ct.kind
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    tm.note_present,
    co.company_name,
    co.company_type,
    co.company_count
FROM TopMovies tm
LEFT JOIN CompanyInfo co ON tm.title_id = co.movie_id
WHERE tm.note_present > 0
ORDER BY tm.production_year DESC, tm.actor_count DESC, co.company_count DESC;
