WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM t.production_year) ORDER BY COUNT(c.person_id) DESC) AS movie_rank,
        COALESCE(NULLIF(t.production_year, 0), 'Unknown') AS production_year_desc
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON c.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
movie_details AS (
    SELECT
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(p.name, 'N/A') AS main_actor,
        SUM(CASE WHEN k.keyword IS NOT NULL THEN 1 ELSE 0 END) AS keyword_count,
        MAX(m.year_of_release) AS latest_year_of_release
    FROM 
        ranked_movies m
    LEFT JOIN 
        cast_info ci ON m.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name p ON ci.person_id = p.person_id
    LEFT JOIN 
        movie_keyword k ON m.movie_id = k.movie_id
    GROUP BY 
        m.movie_id, m.title, m.production_year
),

final_output AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.main_actor,
        md.keyword_count,
        mh.genre AS movie_genre,
        ROW_NUMBER() OVER (ORDER BY md.keyword_count DESC, md.production_year DESC) AS ranking
    FROM 
        movie_details md
    LEFT JOIN 
        movie_info mi ON md.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre')
    LEFT JOIN 
        LATERAL (
        SELECT 
            TRIM(STRING_AGG(mii.info, ', ')) AS genre
        FROM 
            movie_info_idx mii
        WHERE 
            mii.movie_id = md.movie_id
        ) mh ON TRUE
    WHERE 
        md.keyword_count > 0
)

SELECT 
    *
FROM 
    final_output
WHERE 
    NOT EXISTS (
        SELECT 
            1 
        FROM 
            movie_link ml 
        WHERE 
            ml.movie_id = final_output.movie_id AND ml.linked_movie_id IS NULL
    )
AND 
    (ranking < 10 OR movie_genre IS NOT NULL)
ORDER BY 
    ranking;
