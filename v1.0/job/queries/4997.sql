WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS num_cast_members,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
RecentTitles AS (
    SELECT 
        r.title,
        r.production_year,
        r.num_cast_members
    FROM 
        RankedMovies r
    WHERE 
        r.rank <= 5
),
CompanyMovieCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.id) AS num_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    rt.num_cast_members,
    COALESCE(cmc.num_companies, 0) AS num_companies,
    CASE 
        WHEN rt.num_cast_members > 20 THEN 'Large Cast'
        WHEN rt.num_cast_members BETWEEN 10 AND 20 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    RecentTitles rt
LEFT JOIN 
    CompanyMovieCounts cmc ON rt.title = (SELECT title FROM aka_title WHERE id = cmc.movie_id LIMIT 1)
ORDER BY 
    rt.production_year DESC, 
    rt.num_cast_members DESC;
