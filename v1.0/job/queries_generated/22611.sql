WITH RecursiveRatings AS (
    SELECT 
        t.id AS title_id,
        t.title,
        COALESCE(AVG(r.rating), 0) AS avg_rating,
        COUNT(r.rating) AS rating_count,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY COALESCE(AVG(r.rating), 0) DESC) AS rn
    FROM 
        title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    LEFT JOIN 
        LATERAL (SELECT CAST(SUBSTRING(mi.info FROM '\d+(\.\d+)?') AS FLOAT) AS rating 
                  FROM movie_info mi 
                  WHERE mi.movie_id = t.id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')) r ON TRUE
    GROUP BY 
        t.id
),
FilteredActors AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        MAX(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS max_order
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.person_id, a.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
CompanyMovieCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
HistoricMovies AS (
    SELECT 
        t.id,
        t.title,
        COUNT(DISTINCT kc.keyword) AS keyword_count
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword kc ON mk.keyword_id = kc.id
    WHERE 
        t.production_year < 2000
    GROUP BY 
        t.id, t.title
)
SELECT 
    r.title,
    r.avg_rating,
    r.rating_count,
    f.name AS actor_name,
    f.movie_count AS actor_movie_count,
    c.company_count,
    h.keyword_count
FROM 
    RecursiveRatings r
JOIN 
    FilteredActors f ON r.title_id IN (SELECT movie_id FROM cast_info WHERE person_id = f.person_id)
LEFT JOIN 
    CompanyMovieCounts c ON r.title_id = c.movie_id
LEFT JOIN 
    HistoricMovies h ON r.title_id = h.id
WHERE 
    r.avg_rating IS NOT NULL 
    AND r.rating_count > 3 
    AND c.company_count > 2
ORDER BY 
    r.avg_rating DESC,
    f.actor_movie_count DESC,
    h.keyword_count DESC
LIMIT 10;
