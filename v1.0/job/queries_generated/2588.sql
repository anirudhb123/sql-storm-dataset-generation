WITH RecursiveTitleCTE AS (
    SELECT 
        t.id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
TopActors AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.person_id, a.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
RelevantMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(mk.keyword, 'No Keyword') AS keyword
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    WHERE 
        m.production_year > 2000
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        COUNT(mk.id) AS keyword_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_keyword mk ON mc.movie_id = mk.movie_id
    GROUP BY 
        mc.movie_id, c.name
)
SELECT 
    rt.title AS Movie_Title,
    rt.production_year AS Year,
    ta.name AS Top_Actor,
    cm.company_name AS Production_Company,
    cm.keyword_count AS Associated_Keywords,
    COALESCE(ta.movie_count, 0) AS Actor_Movies
FROM 
    RecursiveTitleCTE rt
LEFT JOIN 
    TopActors ta ON ta.movie_count >= 5
LEFT JOIN 
    CompanyMovies cm ON cm.movie_id = rt.id
WHERE 
    rt.rn <= 10
ORDER BY 
    rt.production_year DESC, rt.title;
