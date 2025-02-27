WITH RecursiveCTE AS (
    SELECT 
        a.id AS aka_id,
        a.person_id,
        a.name AS aka_name,
        a.name_pcode_cf,
        a.name_pcode_nf,
        a.surname_pcode,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS row_num
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
        AND c.nr_order = (
            SELECT MAX(nr_order)
            FROM cast_info ci
            WHERE ci.movie_id = c.movie_id
        )
),
AggregatedData AS (
    SELECT 
        p.person_id,
        COUNT(DISTINCT mk.keyword) AS keyword_count,
        MAX(t.production_year) AS latest_movie_year,
        STRING_AGG(DISTINCT a.aka_name, ', ') AS alternate_names
    FROM 
        RecursiveCTE p
    LEFT JOIN 
        movie_keyword mk ON p.movie_title = mk.movie_id
    LEFT JOIN 
        title t ON p.movie_title = t.id
    LEFT JOIN 
        aka_name a ON p.person_id = a.person_id
    GROUP BY 
        p.person_id
)
SELECT 
    ad.*,
    CASE
        WHEN ad.keyword_count > 5 THEN 'High'
        WHEN ad.keyword_count BETWEEN 2 AND 5 THEN 'Medium'
        ELSE 'Low'
    END AS keyword_diversity,
    (SELECT COUNT(*) FROM known_movies km WHERE km.person_id = ad.person_id) AS known_movies,
    COALESCE((SELECT AVG(CAST(SUBSTRING(m.info FROM '[0-9]+') AS INTEGER)) 
                FROM movie_info m 
                WHERE m.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = ad.person_id)
                AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')),
              0) AS avg_rating
FROM 
    AggregatedData ad
LEFT JOIN 
    (SELECT km.person_id 
     FROM known_movies km 
     GROUP BY km.person_id 
     HAVING COUNT(km.movie_id) > 0) filtered_km ON ad.person_id = filtered_km.person_id
WHERE 
    ad.latest_movie_year IS NOT NULL 
    AND (ad.keyword_count IS NOT NULL OR ad.latest_movie_year > 2000)
ORDER BY 
    ad.keyword_count DESC, 
    ad.latest_movie_year DESC
LIMIT 100;
