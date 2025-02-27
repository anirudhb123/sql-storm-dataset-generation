WITH recursive movie_tree AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        CAST(mk.id AS integer) AS keyword_id,
        COALESCE(cn.name, 'Unknown Company') AS company_name
    FROM 
        aka_title mt
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    WHERE 
        mt.production_year BETWEEN 1990 AND 2023

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        CAST(mk.id AS integer) AS keyword_id,
        COALESCE(cn.name, 'Unknown Company') AS company_name
    FROM 
        aka_title mt
    JOIN movie_link ml ON mt.id = ml.movie_id
    JOIN movie_tree mt2 ON ml.linked_movie_id = mt2.movie_id
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
), 

status_count AS (
    SELECT 
        movie_id,
        COUNT(*) AS num_cast_members
    FROM 
        complete_cast cc
    GROUP BY 
        movie_id
),

ranked_movies AS (
    SELECT 
        mt.movie_id,
        mt.title,
        mt.production_year,
        mt.keyword,
        mt.company_name,
        sc.num_cast_members,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY sc.num_cast_members DESC) AS rank
    FROM 
        movie_tree mt
    LEFT JOIN status_count sc ON mt.movie_id = sc.movie_id
)

SELECT 
    rm.title,
    rm.production_year,
    rm.keyword,
    rm.company_name,
    COALESCE(rm.num_cast_members, 0) AS cast_member_count,
    (CASE 
        WHEN rm.num_cast_members IS NULL THEN 'No Cast Info' 
        WHEN rm.num_cast_members = 0 THEN 'NoCast' 
        ELSE 'HasCast' 
    END) AS cast_status,
    CASE 
        WHEN rm.rank IS NOT NULL THEN 'Ranked'
        ELSE 'Unranked'
    END AS ranking_status
FROM 
    ranked_movies rm
WHERE 
    rm.num_cast_members IS NULL 
    OR (rm.rank <= 5 AND rm.production_year = 2022)
ORDER BY 
    rm.production_year DESC, rm.rank;
