WITH Recursive_Actors AS (
    SELECT 
        a.person_id,
        ak.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS rn
    FROM aka_name ak
    JOIN cast_info c ON ak.person_id = c.person_id
    GROUP BY a.person_id, ak.name
), 
Movies_With_Companions AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(COUNT(mc.company_id), 0) AS company_count
    FROM aka_title m
    LEFT JOIN movie_companies mc ON m.id = mc.movie_id
    WHERE m.production_year BETWEEN 2000 AND 2023
    GROUP BY m.id, m.title
), 
Keyword_Info AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ' ORDER BY k.keyword) AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    ra.actor_name,
    ra.movie_count,
    mwc.title AS movie_title,
    mwc.company_count,
    ki.keywords,
    CASE 
        WHEN mwc.company_count IS NULL THEN 'No Companies'
        WHEN mwc.company_count > 5 THEN 'Large Production'
        ELSE 'Standard Production'
    END AS production_type,
    CASE 
        WHEN ra.movie_count > 10 THEN 'Frequent Actor'
        ELSE 'Occasional Actor'
    END AS actor_activity
FROM Recursive_Actors ra
JOIN Movies_With_Companions mwc ON mwc.movie_id IN (
    SELECT c.movie_id 
    FROM cast_info c 
    WHERE c.person_id = ra.person_id
)
LEFT JOIN Keyword_Info ki ON mwc.movie_id = ki.movie_id
WHERE 
    ra.movie_count IS NOT NULL 
    AND (LOWER(ra.actor_name) LIKE 'a%' OR mwc.company_count >= 3)
ORDER BY ra.movie_count DESC, mwc.company_count DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
