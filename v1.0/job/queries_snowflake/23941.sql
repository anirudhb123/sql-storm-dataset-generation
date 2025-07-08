WITH RECURSIVE MovieCTE AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        SUM(CASE WHEN c.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS role_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.movie_id = c.movie_id 
    GROUP BY 
        m.id, m.title, m.production_year
),
KeywordCount AS (
    SELECT 
        mk.movie_id, 
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk 
    GROUP BY 
        mk.movie_id
),
MovieDetails AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(k.keyword_count, 0) AS keyword_count,
        COALESCE(ct.actor_count, 0) AS actor_count,
        COALESCE(ct.role_count, 0) AS role_count,
        CASE 
            WHEN m.production_year < 2000 THEN 'Classic' 
            WHEN m.production_year BETWEEN 2000 AND 2010 THEN 'Modern' 
            ELSE 'Recent' 
        END AS era
    FROM 
        MovieCTE ct
    JOIN 
        aka_title m ON ct.movie_id = m.movie_id
    LEFT JOIN 
        KeywordCount k ON m.movie_id = k.movie_id
)
SELECT 
    d.title,
    d.production_year,
    d.era,
    d.actor_count,
    d.keyword_count,
    ROUND(AVG(d.role_count) OVER (PARTITION BY d.era), 2) AS avg_role_count,
    (SELECT COUNT(*) 
     FROM movie_companies mc 
     WHERE mc.movie_id = d.movie_id AND mc.company_type_id = 1) AS production_company_count
FROM 
    MovieDetails d
WHERE 
    d.actor_count > 0 
    AND (d.keyword_count IS NULL OR d.keyword_count >= 5)
ORDER BY 
    d.production_year DESC, 
    d.actor_count DESC;
