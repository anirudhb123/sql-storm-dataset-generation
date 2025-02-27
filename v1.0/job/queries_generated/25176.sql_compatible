
WITH TitleRanked AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year >= 2000
), 
MovieKeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
), 
TopActors AS (
    SELECT 
        a.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.name
    HAVING 
        COUNT(ci.movie_id) > 5
    ORDER BY 
        movie_count DESC
    LIMIT 10
), 
CompanyMovieCounts AS (
    SELECT 
        mct.movie_id,
        COUNT(DISTINCT mct.company_id) AS company_count
    FROM 
        movie_companies mct
    JOIN 
        complete_cast cc ON mct.movie_id = cc.movie_id
    GROUP BY 
        mct.movie_id
)

SELECT 
    t.title AS movie_title,
    t.production_year,
    tr.title_rank,
    km.keyword_count,
    ta.actor_name,
    cm.company_count
FROM 
    TitleRanked tr
JOIN 
    title t ON tr.title_id = t.id
LEFT JOIN 
    MovieKeywordCount km ON t.id = km.movie_id
LEFT JOIN 
    TopActors ta ON t.id IN (SELECT ci.movie_id FROM cast_info ci WHERE ci.movie_id = t.id)
LEFT JOIN 
    CompanyMovieCounts cm ON t.id = cm.movie_id
WHERE 
    km.keyword_count IS NOT NULL
ORDER BY 
    t.production_year DESC, 
    tr.title_rank;
