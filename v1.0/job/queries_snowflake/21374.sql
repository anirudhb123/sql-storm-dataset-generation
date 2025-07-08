
WITH movie_count AS (
    SELECT 
        m.id AS movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        AVG(y.production_year) AS avg_year
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.movie_id = c.movie_id 
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        title y ON m.id = y.id
    GROUP BY 
        m.id
),
movie_info_extended AS (
    SELECT 
        mi.movie_id,
        COALESCE(mi.info, 'No Info') AS movie_information,
        CASE 
            WHEN COUNT(DISTINCT k.keyword) > 0 THEN LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) 
            ELSE 'No Keywords' 
        END AS keywords
    FROM 
        movie_info mi 
    JOIN 
        movie_keyword mk ON mi.movie_id = mk.movie_id 
    JOIN 
        keyword k ON mk.keyword_id = k.id 
    GROUP BY 
        mi.movie_id, mi.info
),
ranked_movies AS (
    SELECT 
        mc.movie_id,
        mc.cast_count,
        mc.avg_year,
        ROW_NUMBER() OVER (PARTITION BY mc.cast_count ORDER BY mc.avg_year DESC) AS rank
    FROM 
        movie_count mc
    WHERE 
        mc.cast_count >= 3
),
final_selection AS (
    SELECT 
        r.movie_id,
        r.cast_count,
        r.avg_year,
        m.movie_information,
        m.keywords
    FROM 
        ranked_movies r
    LEFT JOIN 
        movie_info_extended m ON r.movie_id = m.movie_id
    WHERE 
        r.rank <= 10 
        OR (r.rank IS NULL AND r.cast_count > 5)
)
SELECT 
    f.movie_id,
    (f.cast_count * COALESCE(NULLIF(f.avg_year, 0), 1)) AS calc_metric,
    f.movie_information,
    f.keywords
FROM 
    final_selection f
ORDER BY 
    calc_metric DESC, f.movie_id ASC;
