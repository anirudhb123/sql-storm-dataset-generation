WITH MovieCTE AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
),

ActorMovieCounts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    GROUP BY 
        c.person_id
),

PersonDetails AS (
    SELECT 
        p.id AS person_id,
        a.name,
        pc.movie_count
    FROM 
        aka_name a
    INNER JOIN 
        ActorMovieCounts pc ON a.person_id = pc.person_id
)

SELECT 
    pd.name,
    COUNT(DISTINCT m.title_id) AS featured_movies,
    STRING_AGG(DISTINCT m.title, ', ') AS movie_titles,
    SUM(CASE WHEN m.production_year >= 2000 THEN 1 ELSE 0 END) AS movies_since_2000,
    MIN(m.production_year) AS earliest_movie_year,
    (SELECT COUNT(*) FROM title WHERE kind_id = (SELECT id FROM kind_type WHERE kind = 'feature')) AS total_feature_titles
FROM 
    PersonDetails pd
LEFT JOIN 
    MovieCTE m ON pd.person_id IN (SELECT c.person_id FROM cast_info c WHERE c.movie_id = m.title_id)
GROUP BY 
    pd.name
HAVING 
    COUNT(DISTINCT m.title_id) > 5
ORDER BY 
    featured_movies DESC;
