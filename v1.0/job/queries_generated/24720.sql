WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ka.id) DESC) AS rank
    FROM
        aka_title AS t
    LEFT JOIN
        movie_keyword AS mk ON t.movie_id = mk.movie_id
    LEFT JOIN
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN
        movie_info AS mi ON t.movie_id = mi.movie_id AND mi.info_type_id = (
            SELECT id FROM info_type WHERE info = 'Genre' LIMIT 1
        )
    LEFT JOIN 
        aka_name AS ka ON t.movie_id = ka.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS roles_filled
    FROM 
        cast_info AS ci
    GROUP BY 
        ci.movie_id
),
genres AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS genre_list
    FROM 
        movie_info AS mi
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre' LIMIT 1)
    GROUP BY 
        mi.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    cs.total_cast,
    cs.roles_filled,
    ge.genre_list,
    COALESCE(NULLIF(cs.total_cast, 0), 1) AS adjusted_total_cast,
    CASE WHEN rt.rank <= 5 THEN 'Top 5 Titles' ELSE 'Other Titles' END AS title_rank_category
FROM 
    ranked_titles AS rt
LEFT JOIN 
    cast_summary AS cs ON rt.title_id = cs.movie_id
LEFT JOIN 
    genres AS ge ON rt.title_id = ge.movie_id
WHERE 
    rt.production_year >= 2000
    AND rt.rank < 10
ORDER BY 
    rt.production_year DESC, 
    rt.rank;
