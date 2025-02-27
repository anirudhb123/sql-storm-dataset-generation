WITH RECURSIVE title_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        th.depth + 1
    FROM 
        aka_title mt
    INNER JOIN 
        title_hierarchy th ON mt.episode_of_id = th.movie_id
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_member_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_details AS (
    SELECT 
        th.movie_id,
        th.title,
        th.production_year,
        cs.total_cast,
        cs.cast_member_names,
        ks.keywords,
        ROW_NUMBER() OVER (PARTITION BY th.production_year ORDER BY th.title) AS title_rank
    FROM 
        title_hierarchy th
    LEFT JOIN 
        cast_summary cs ON th.movie_id = cs.movie_id
    LEFT JOIN 
        keyword_summary ks ON th.movie_id = ks.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    COALESCE(md.total_cast, 0) AS total_cast,
    md.cast_member_names,
    md.keywords,
    CASE 
        WHEN md.title_rank IS NULL THEN 'Unranked'
        WHEN md.title_rank <= 5 THEN 'Top 5'
        ELSE 'Others'
    END AS title_ranking
FROM 
    movie_details md
ORDER BY 
    md.production_year DESC, 
    CHAR_LENGTH(md.title) DESC, 
    md.title;
