WITH RecursiveTitleCTE AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        CAST(NULL AS INTEGER) AS parent_id
    FROM title t
    WHERE t.production_year IS NOT NULL AND t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        t2.id,
        t2.title,
        t2.production_year,
        t2.kind_id,
        rtc.title_id AS parent_id
    FROM title t2
    JOIN movie_link ml ON t2.id = ml.linked_movie_id
    JOIN RecursiveTitleCTE rtc ON ml.movie_id = rtc.title_id
    WHERE t2.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        t.title,
        COALESCE(info.info, 'No additional info') AS additional_info,
        c.name AS company_name,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY ak.name) AS actor_rank
    FROM RecursiveTitleCTE t
    LEFT JOIN movie_info mi ON t.title_id = mi.movie_id
    LEFT JOIN info_type it ON mi.info_type_id = it.id
    LEFT JOIN movie_companies mc ON t.title_id = mc.movie_id
    LEFT JOIN company_name c ON mc.company_id = c.id
    LEFT JOIN cast_info ci ON t.title_id = ci.movie_id
    LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        (t.production_year BETWEEN 1990 AND 2000 OR t.title ILIKE '%mystery%')
        AND (it.info IS NOT NULL OR it.info IS NULL) 
        AND (ci.note IS NOT NULL OR ak.name IS NULL)
)
SELECT 
    title,
    additional_info,
    company_name,
    STRING_AGG(actor_name, ', ' ORDER BY actor_rank) AS actors,
    COUNT(DISTINCT company_name) AS distinct_companies,
    COUNT(DISTINCT actor_name) FILTER (WHERE actor_rank <= 5) AS top_actors_count,
    COUNT(*) AS total_appearances
FROM MovieDetails
GROUP BY title, additional_info, company_name
HAVING COUNT(DISTINCT actor_name) > 2 AND 
       COUNT(DISTINCT company_name) > 1
ORDER BY COUNT(*) DESC, title ASC
LIMIT 100;
