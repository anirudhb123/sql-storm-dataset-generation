WITH MovieStats AS (
    SELECT 
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        COUNT(DISTINCT m.id) AS company_count,
        AVG(mi.info::numeric) AS avg_rating
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN 
        cast_info c ON c.movie_id = t.id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = t.id AND mi.info_type_id in (SELECT id FROM info_type WHERE info = 'Rating')
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.production_year
),
CompanyTypes AS (
    SELECT 
        c.id AS company_id,
        ct.kind AS company_type,
        COUNT(m.id) AS total_movies
    FROM 
        company_name c
    JOIN 
        movie_companies mc ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        c.id, ct.kind
),
KeywordCounts AS (
    SELECT 
        m.id AS movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    GROUP BY 
        m.id
)
SELECT 
    ms.production_year,
    COALESCE(ms.actor_count, 0) AS actor_count,
    COALESCE(ct.company_type, 'Unknown') AS company_type,
    COALESCE(ct.total_movies, 0) AS total_movies,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    ROW_NUMBER() OVER (PARTITION BY ms.production_year ORDER BY ms.actor_count DESC) AS actor_rank
FROM 
    MovieStats ms
LEFT JOIN 
    CompanyTypes ct ON ct.total_movies = (SELECT MAX(total_movies) FROM CompanyTypes)
LEFT JOIN 
    KeywordCounts kc ON kc.movie_id IN (SELECT id FROM aka_title WHERE production_year = ms.production_year)
ORDER BY 
    ms.production_year DESC, actor_count DESC;
