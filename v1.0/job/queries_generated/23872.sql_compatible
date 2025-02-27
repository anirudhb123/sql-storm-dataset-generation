
WITH RecursiveMovieCTE AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER(PARTITION BY m.production_year ORDER BY m.title) AS rn
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
EnhancedCastInfo AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS unique_actors,
        STRING_AGG(DISTINCT CONCAT_WS(' ', a.name, a.surname_pcode), ', ') AS actor_list
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
MovieKeywordStats AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
DetailedInfo AS (
    SELECT 
        m.movie_id,
        m.unique_actors,
        m.actor_list,
        COALESCE(k.keyword_count, 0) AS keyword_count
    FROM 
        EnhancedCastInfo m
    LEFT JOIN 
        MovieKeywordStats k ON m.movie_id = k.movie_id
),
ComplexAggregation AS (
    SELECT 
        d.movie_id,
        d.unique_actors,
        d.actor_list,
        d.keyword_count,
        CASE 
            WHEN d.keyword_count > 0 THEN 
                'Key Movie' 
            ELSE 
                'Minor Movie' 
        END AS classification,
        SUM(d.unique_actors) OVER (ORDER BY d.keyword_count DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_actors
    FROM 
        DetailedInfo d
)
SELECT 
    R.movie_id,
    M.title,
    M.production_year,
    R.unique_actors,
    R.actor_list,
    R.classification,
    R.running_total_actors
FROM 
    ComplexAggregation R
JOIN 
    RecursiveMovieCTE M ON R.movie_id = M.movie_id
WHERE 
    R.unique_actors IS NOT NULL
ORDER BY 
    R.running_total_actors DESC, 
    M.production_year DESC
LIMIT 50;
