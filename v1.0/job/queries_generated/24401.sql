WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS actor_count_rank,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT n.name, ', ') FILTER (WHERE n.name IS NOT NULL) AS actor_names
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        aka_name n ON c.person_id = n.person_id
    GROUP BY 
        a.id, a.title, a.production_year
),

TopMovies AS (
    SELECT 
        movie_id, title, production_year, actor_count
    FROM 
        RankedMovies
    WHERE 
        actor_count_rank = 1
),

HighRatedMovies AS (
    SELECT 
        m.movie_id, 
        m.title, 
        m.production_year, 
        COALESCE(mi.info, 'No Rating') AS rating_info
    FROM 
        TopMovies m
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
)

SELECT 
    hm.movie_id, 
    hm.title, 
    hm.production_year, 
    hm.rating_info,
    mcn.name AS production_company,
    kw.keyword AS movie_keyword
FROM 
    HighRatedMovies hm
LEFT JOIN 
    movie_companies mc ON hm.movie_id = mc.movie_id
LEFT JOIN 
    company_name mcn ON mc.company_id = mcn.id AND mcn.country_code IS NOT NULL
LEFT JOIN 
    movie_keyword mk ON hm.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    (hm.rating_info IS NOT NULL OR hm.rating_info = 'No Rating')
    AND (mcn.name IS NOT NULL OR mcn.name LIKE '%Studios%')
ORDER BY 
    hm.production_year DESC, 
    hm.title ASC;

