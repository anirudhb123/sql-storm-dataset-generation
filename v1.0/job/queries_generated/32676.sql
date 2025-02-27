WITH RECURSIVE Movie_Hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(NULLIF(mt.season_nr, 0), -1) AS season_nr,
        COALESCE(NULLIF(mt.episode_nr, 0), -1) AS episode_nr,
        0 AS depth
    FROM 
        aka_title mt 
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(NULLIF(mt.season_nr, 0), -1) AS season_nr,
        COALESCE(NULLIF(mt.episode_nr, 0), -1) AS episode_nr,
        mh.depth + 1
    FROM 
        aka_title mt
    JOIN 
        Movie_Hierarchy mh ON mt.episode_of_id = mh.movie_id
),

CastRanked AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    INNER JOIN 
        aka_name a ON ci.person_id = a.person_id
),

MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.season_nr,
    mh.episode_nr,
    COALESCE(cr.actor_name, 'No Cast') AS first_actor,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COUNT(DISTINCT mc.company_id) AS company_count,
    COUNT(DISTINCT ci.person_id) AS total_cast
FROM 
    Movie_Hierarchy mh
LEFT JOIN 
    CastRanked cr ON mh.movie_id = cr.movie_id AND cr.actor_rank = 1
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    MovieKeywords mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.season_nr, mh.episode_nr, cr.actor_name, mk.keywords
ORDER BY 
    mh.production_year DESC, mh.movie_id;
