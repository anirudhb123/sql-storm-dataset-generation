WITH MovieStats AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        AVG(CASE WHEN ai.info_type_id = 1 THEN CAST(ai.info AS FLOAT) END) AS average_rating,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM title a
    LEFT JOIN movie_info ai ON a.id = ai.movie_id AND ai.info_type_id = 1
    LEFT JOIN complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN cast_info c ON cc.subject_id = c.id
    LEFT JOIN movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE a.production_year IS NOT NULL
    GROUP BY a.id, a.title, a.production_year
),
HighestRatedMovies AS (
    SELECT 
        title,
        production_year,
        actor_count,
        average_rating,
        keywords,
        ROW_NUMBER() OVER (ORDER BY average_rating DESC) as rank
    FROM MovieStats
),
RelevantMovies AS (
    SELECT 
        hr.title,
        hr.production_year,
        hr.actor_count,
        hr.average_rating,
        hr.keywords
    FROM HighestRatedMovies hr
    WHERE hr.rank <= 10
),
TopCompanies AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS company_count
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id, cn.name, ct.kind
),
FinalReport AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actor_count,
        rm.average_rating,
        rm.keywords,
        COALESCE(tc.company_name, 'Independent') AS company_name,
        COALESCE(tc.company_type, 'N/A') AS company_type,
        tc.company_count
    FROM RelevantMovies rm
    LEFT JOIN TopCompanies tc ON rm.title = (SELECT title FROM title WHERE id = tc.movie_id LIMIT 1)
)
SELECT 
    *,
    CASE 
        WHEN actor_count > 5 THEN 'Ensemble Cast'
        WHEN actor_count BETWEEN 3 AND 5 THEN 'Moderate Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM FinalReport
ORDER BY average_rating DESC, production_year DESC;
