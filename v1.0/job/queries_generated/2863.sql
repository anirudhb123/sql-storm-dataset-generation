WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(ca.name, 'Unknown') AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_year,
        COUNT(DISTINCT mk.keyword_id) OVER (PARTITION BY t.id) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ca ON ci.person_id = ca.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year IS NOT NULL
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Feature%')
        AND NOT EXISTS (
            SELECT 1 
            FROM movie_info mi 
            WHERE mi.movie_id = t.id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rated')
        )
),
MovieAggregates AS (
    SELECT 
        production_year,
        COUNT(title) AS total_movies,
        AVG(keyword_count) AS avg_keywords,
        MAX(rank_year) AS latest_rank
    FROM 
        RankedMovies
    GROUP BY 
        production_year
)
SELECT 
    ma.production_year,
    ma.total_movies,
    ma.avg_keywords,
    ca.kind AS company_type,
    COALESCE(SUM(CASE WHEN mc.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS company_movies
FROM 
    MovieAggregates ma
LEFT JOIN 
    movie_companies mc ON ma.production_year = (SELECT production_year FROM aka_title WHERE id = mc.movie_id)
LEFT JOIN 
    company_type ca ON mc.company_type_id = ca.id
GROUP BY 
    ma.production_year, ca.kind
HAVING 
    ma.total_movies > 5
ORDER BY 
    ma.production_year DESC;
