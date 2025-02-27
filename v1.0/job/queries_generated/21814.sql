WITH Recursive Cohort AS (
    SELECT 
        a.id AS aka_id, 
        a.person_id AS person_id, 
        a.name AS aka_name, 
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY a.name) AS name_order
    FROM aka_name a
), TitleStats AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year,
        COUNT(DISTINCT c.person_id) AS num_cast_members,
        MAX(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS has_cast_note
    FROM aka_title t
    LEFT JOIN cast_info c ON t.id = c.movie_id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.id, t.title, t.production_year
), CompanyPerformance AS (
    SELECT 
        mc.movie_id,
        SUM(CASE WHEN c.kind_id = 1 THEN 1 ELSE 0 END) AS num_production_companies,
        COUNT(DISTINCT co.id) AS total_companies
    FROM movie_companies mc
    JOIN company_type c ON mc.company_type_id = c.id
    LEFT JOIN company_name co ON mc.company_id = co.id
    GROUP BY mc.movie_id
), MoviesWithKeyword AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM aka_title m
    JOIN movie_keyword mk ON m.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY m.id
), FinalResults AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        cs.num_cast_members,
        p.num_production_companies,
        p.total_companies,
        k.keywords,
        COALESCE(a.aka_name, 'Unknown') AS first_aka_name
    FROM TitleStats cs
    JOIN CompanyPerformance p ON cs.title_id = p.movie_id
    LEFT JOIN MoviesWithKeyword k ON cs.title_id = k.movie_id
    LEFT JOIN Cohort a ON cs.num_cast_members > 0 AND a.name_order = 1
    WHERE cs.has_cast_note = 1 AND cs.production_year >= 2000
)

SELECT 
    title_id,
    title,
    production_year,
    num_cast_members,
    num_production_companies,
    total_companies,
    keywords,
    first_aka_name,
    CASE 
        WHEN num_cast_members > 20 THEN 'Large Cast'
        WHEN num_cast_members BETWEEN 10 AND 20 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size
FROM FinalResults
WHERE total_companies IS NOT NULL
ORDER BY production_year DESC, num_cast_members DESC
LIMIT 50 OFFSET 10;
