WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
ClassicMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(STRING_AGG(DISTINCT CONCAT(a.name, ' (', rt.role, ')'), ', ') FILTER (WHERE a.name IS NOT NULL), 'No Cast') AS cast_list,
        COALESCE(SUM(mo.info_type_id)::text, '0') AS info_count
    FROM 
        RankedMovies rm
    JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    LEFT JOIN 
        movie_info mo ON rm.movie_id = mo.movie_id
    WHERE 
        rm.production_year < 1970
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
)
SELECT 
    cm.movie_id,
    cm.title,
    cm.production_year,
    cm.cast_list,
    CASE 
        WHEN cm.info_count::integer > 5 THEN 'Rich in Info'
        WHEN cm.info_count::integer = 0 THEN 'No Info'
        ELSE 'Moderate Info'
    END AS info_quality,
    (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = cm.movie_id) AS keyword_count,
    COALESCE((SELECT AVG(sub.movie_years) FROM (SELECT EXTRACT(YEAR FROM age(TO_DATE(cm.production_year::text, 'YYYY')))) AS movie_years 
                   FROM title WHERE id = cm.movie_id) AS sub), 0) AS average_years_since_release
FROM 
    ClassicMovies cm
WHERE 
    rank_by_cast <= 3
ORDER BY 
    cm.production_year DESC, info_quality DESC
LIMIT 10;
