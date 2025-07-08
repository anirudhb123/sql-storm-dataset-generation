
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),

TopActors AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(c.movie_id) AS movie_count,
        RANK() OVER (ORDER BY COUNT(c.movie_id) DESC) AS actor_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id, a.name
    HAVING 
        COUNT(c.movie_id) > 5
),

CompanyStats AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),

MoviesWithKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    t.title AS Movie_Title,
    t.production_year AS Release_Year,
    ra.name AS Actor_Name,
    cs.companies AS Production_Companies,
    mk.keywords AS Related_Keywords
FROM 
    RankedTitles t
LEFT JOIN 
    TopActors ra ON ra.actor_rank <= 5
LEFT JOIN 
    CompanyStats cs ON cs.movie_id = t.title_id
LEFT JOIN 
    MoviesWithKeywords mk ON mk.movie_id = t.title_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND (t.title LIKE '%Action%' OR t.title LIKE '%Adventure%')
    AND COALESCE(cs.company_count, 0) > 0
ORDER BY 
    t.production_year DESC, 
    t.title;
