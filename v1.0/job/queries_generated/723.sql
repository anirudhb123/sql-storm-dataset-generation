WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) as year_rank,
        COUNT(*) OVER () as total_movies
    FROM 
        aka_title a
    WHERE 
        a.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
),
PersonRoles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.person_role_id = r.id
    GROUP BY 
        c.movie_id, r.role
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(p.actor_count, 0) AS actor_count,
    CASE 
        WHEN m.year_rank IS NULL THEN 'N/A'
        ELSE CONCAT('Rank ', m.year_rank, ' of ', m.total_movies)
    END AS ranking_info,
    SUBSTRING(m.title FROM 1 FOR 20) || ' ...' AS short_title,
    COUNT(DISTINCT mk.keyword) AS keyword_count
FROM 
    RankedMovies m 
LEFT JOIN 
    PersonRoles p ON m.production_year = p.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = m.title LIMIT 1)
WHERE 
    m.production_year >= 2000
GROUP BY 
    m.title, m.production_year, m.year_rank, m.total_movies
ORDER BY 
    m.production_year DESC, m.title
LIMIT 100;
