WITH RankedTitles AS (
    SELECT 
        title.id AS title_id,
        title.title AS movie_title,
        aka_name.name AS actor_name,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.id ORDER BY aka_name.name) AS actor_rank
    FROM 
        title
    JOIN 
        cast_info ON cast_info.movie_id = title.id
    JOIN 
        aka_name ON aka_name.person_id = cast_info.person_id
    WHERE 
        title.production_year >= 2000
),
KeywordStats AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT keyword_id) AS keyword_count
    FROM 
        movie_keyword
    GROUP BY 
        movie_id
),
CompanyStats AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT company_id) AS company_count
    FROM 
        movie_companies
    GROUP BY 
        movie_id
)
SELECT 
    rt.movie_title,
    rt.production_year,
    STRING_AGG(rt.actor_name, ', ' ORDER BY rt.actor_rank) AS actors,
    COALESCE(ks.keyword_count, 0) AS keyword_count,
    COALESCE(cs.company_count, 0) AS company_count
FROM 
    RankedTitles rt
LEFT JOIN 
    KeywordStats ks ON rt.title_id = ks.movie_id
LEFT JOIN 
    CompanyStats cs ON rt.title_id = cs.movie_id
GROUP BY 
    rt.movie_title, rt.production_year
ORDER BY 
    rt.production_year DESC, rt.movie_title;
