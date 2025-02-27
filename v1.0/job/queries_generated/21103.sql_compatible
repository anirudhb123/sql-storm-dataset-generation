
WITH MovieStats AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT c.id) AS cast_count,
        COUNT(DISTINCT k.id) AS keyword_count,
        SUM(CASE WHEN mc.company_type_id IS NOT NULL THEN 1 ELSE 0 END) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY m.production_year DESC) AS rank
    FROM 
        aka_name a
        JOIN cast_info c ON a.person_id = c.person_id
        JOIN aka_title t ON c.movie_id = t.movie_id
        JOIN title m ON m.id = t.movie_id
        LEFT JOIN movie_keyword mk ON mk.movie_id = m.id
        LEFT JOIN keyword k ON k.id = mk.keyword_id
        LEFT JOIN movie_companies mc ON mc.movie_id = m.id
    WHERE 
        m.production_year IS NOT NULL 
        AND a.name IS NOT NULL
        AND m.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%')
    GROUP BY 
        a.name, t.title, m.production_year, a.person_id
),
RankedStats AS (
    SELECT 
        actor_name,
        movie_title,
        production_year,
        cast_count,
        keyword_count,
        company_count,
        rank
    FROM 
        MovieStats
    WHERE 
        rank <= 5
),
MaxCompanies AS (
    SELECT 
        production_year,
        MAX(company_count) AS max_company_count
    FROM 
        RankedStats
    GROUP BY 
        production_year
)
SELECT 
    rs.actor_name,
    rs.movie_title,
    rs.production_year,
    rs.cast_count,
    rs.keyword_count,
    rs.company_count,
    CASE 
        WHEN rs.company_count = mc.max_company_count THEN 'Most Companies'
        ELSE 'Regular'
    END AS company_status
FROM 
    RankedStats rs
    JOIN MaxCompanies mc ON rs.production_year = mc.production_year
WHERE 
    rs.cast_count > (SELECT AVG(cast_count) FROM RankedStats)
    AND (rs.keyword_count IS NULL OR rs.keyword_count >= 3)
ORDER BY 
    rs.production_year DESC, 
    rs.company_count DESC;
