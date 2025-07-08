WITH MovieStatistics AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        MAX(CASE WHEN c.role_id IS NOT NULL THEN c.nr_order END) AS max_cast_order,
        COUNT(DISTINCT mc.company_id) AS total_companies,
        COUNT(DISTINCT mk.keyword_id) AS total_keywords
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.id, t.title
),
RankedMovies AS (
    SELECT 
        movie_id,
        title,
        max_cast_order,
        total_companies,
        total_keywords,
        ROW_NUMBER() OVER (PARTITION BY total_companies ORDER BY total_keywords DESC) AS rank_by_keyword,
        RANK() OVER (ORDER BY max_cast_order DESC) AS rank_by_cast_order
    FROM 
        MovieStatistics
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.max_cast_order,
    rm.total_companies,
    rm.total_keywords,
    COALESCE(rm.rank_by_keyword, 0) AS keyword_rank,
    COALESCE(rm.rank_by_cast_order, 0) AS cast_order_rank
FROM 
    RankedMovies rm
WHERE 
    rm.total_companies > 1
ORDER BY 
    rm.total_keywords DESC, 
    rm.max_cast_order DESC;
