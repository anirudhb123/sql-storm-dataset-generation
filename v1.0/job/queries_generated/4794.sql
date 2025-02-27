WITH ranked_movies AS (
    SELECT 
        a.title, 
        a.production_year, 
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank_in_year
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
distinguished_cast AS (
    SELECT 
        c.movie_id, 
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id
),
movies_with_cast AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        d.cast_count,
        d.cast_names
    FROM 
        aka_title m
    LEFT JOIN 
        distinguished_cast d ON m.id = d.movie_id
    WHERE 
        m.production_year >= 2000
)

SELECT 
    mwc.title,
    mwc.production_year,
    mwc.cast_count,
    CASE 
        WHEN mwc.cast_count IS NULL THEN 'No Cast Information'
        ELSE mwc.cast_names
    END AS cast_details,
    COALESCE((
        SELECT 
            COUNT(DISTINCT mk.keyword) 
        FROM 
            movie_keyword mk 
        WHERE 
            mk.movie_id = mwc.movie_id
    ), 0) AS keyword_count,
    (SELECT 
        GROUP_CONCAT(DISTINCT ct.kind ORDER BY ct.kind) 
     FROM 
        movie_companies mc 
     JOIN 
        company_type ct ON mc.company_type_id = ct.id 
     WHERE 
        mc.movie_id = mwc.movie_id) AS company_kinds
FROM 
    movies_with_cast mwc 
WHERE 
    mwc.rank_in_year <= 5
ORDER BY 
    mwc.production_year DESC, 
    mwc.cast_count DESC;
