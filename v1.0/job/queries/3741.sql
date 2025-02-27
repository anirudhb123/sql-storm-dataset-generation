WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_by_year
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
), 
ActorMovies AS (
    SELECT 
        c.person_id,
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY t.production_year DESC) AS recent_movie_rank
    FROM 
        cast_info c
    JOIN 
        title t ON c.movie_id = t.id
    WHERE 
        c.role_id IN (SELECT id FROM role_type WHERE role LIKE '%actor%' OR role LIKE '%actress%')
)
SELECT 
    a.name,
    COALESCE(a.name_pcode_nf, 'N/A') AS name_pcode_nf,
    COUNT(DISTINCT am.movie_id) AS total_movies,
    STRING_AGG(DISTINCT at.title, ', ') FILTER (WHERE at.production_year > 2000) AS post_2000_titles,
    MAX(at.production_year) AS last_year_active,
    SUM(CASE WHEN am.recent_movie_rank = 1 THEN 1 ELSE 0 END) AS recent_movie_count
FROM 
    aka_name a
LEFT JOIN 
    ActorMovies am ON a.person_id = am.person_id
LEFT JOIN 
    title at ON am.movie_id = at.id
WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.id, a.name, a.name_pcode_nf
HAVING 
    COUNT(DISTINCT am.movie_id) > 5
ORDER BY 
    last_year_active DESC, total_movies DESC;
