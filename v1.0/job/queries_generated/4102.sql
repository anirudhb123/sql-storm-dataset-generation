WITH ranked_movies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(ci.person_id) AS total_cast, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
), 
actor_counts AS (
    SELECT 
        ak.name, 
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
), 
movies_with_keywords AS (
    SELECT 
        t.title, 
        array_agg(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.title
), 
movie_info_rich AS (
    SELECT 
        m.title,
        COUNT(DISTINCT mc.company_id) AS production_companies,
        COALESCE(SUM(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'duration') THEN mi.info::int END), 0) as total_duration
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id 
    GROUP BY 
        m.title
)
SELECT 
    rm.title AS movie_title,
    rm.production_year,
    rm.total_cast,
    ac.movie_count AS actor_movie_count,
    mwk.keywords,
    mir.production_companies,
    mir.total_duration
FROM 
    ranked_movies rm
JOIN 
    actor_counts ac ON ac.movie_count > 10
LEFT JOIN 
    movies_with_keywords mwk ON rm.title = mwk.title
LEFT JOIN 
    movie_info_rich mir ON rm.title = mir.title
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.total_cast DESC;
