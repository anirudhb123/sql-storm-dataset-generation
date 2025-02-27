WITH recursive movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(CAST(SUM(ci.nr_order) OVER (PARTITION BY t.id) AS INTEGER), 0) AS total_cast,
        COALESCE(ARRAY_AGG(DISTINCT ak.name) FILTER (WHERE ak.name IS NOT NULL), '{}') AS cast_names,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS row_num
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year IS NOT NULL
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%')
    GROUP BY 
        t.id, t.title, t.production_year
),
high_cast_movies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.total_cast,
        md.cast_names
    FROM 
        movie_details md
    WHERE 
        md.total_cast > (
            SELECT AVG(total_cast) 
            FROM movie_details
        )
),
complex_cast_info AS (
    SELECT 
        md.movie_id,
        md.title,
        md.total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS all_cast_members,
        CASE 
            WHEN COUNT(DISTINCT ci.role_id) > 2 THEN 'Diverse Cast'
            ELSE 'Niche Cast'
        END AS cast_diversity,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        high_cast_movies md
    LEFT JOIN 
        cast_info ci ON md.movie_id = ci.movie_id
    LEFT JOIN 
        movie_keyword mk ON md.movie_id = mk.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        md.movie_id, md.title, md.total_cast
)
SELECT 
    cci.movie_id,
    cci.title,
    cci.total_cast,
    cci.all_cast_members,
    cci.cast_diversity,
    cci.keyword_count,
    CASE 
        WHEN cci.keyword_count = 0 THEN 'No Keywords'
        WHEN cci.keyword_count > 5 THEN 'Rich Keywords'
        ELSE 'Moderate Keywords'
    END AS keyword_quality
FROM 
    complex_cast_info cci
WHERE 
    EXISTS (
        SELECT 1 
        FROM movie_info mi 
        WHERE mi.movie_id = cci.movie_id 
        AND mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Award%')
    )
ORDER BY 
    cci.total_cast DESC,
    cci.keyword_count ASC,
    cci.title;
