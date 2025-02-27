WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        at.production_year < 2000
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        DENSE_RANK() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS rank
    FROM 
        movie_hierarchy mh
),
cast_details AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
        COUNT(CASE WHEN ak.name IS NULL THEN 1 END) AS null_name_count
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
movie_company_info AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        COUNT(DISTINCT mc.company_type_id) AS company_types_count
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.rank,
    COALESCE(cd.cast_count, 0) AS total_cast,
    COALESCE(cd.cast_names, 'No Cast') AS cast_names,
    cd.null_name_count,
    COALESCE(mci.companies, 'No Companies') AS movie_companies,
    mci.company_types_count
FROM 
    ranked_movies rm
LEFT JOIN 
    cast_details cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    movie_company_info mci ON rm.movie_id = mci.movie_id
WHERE 
    rm.rank <= 10 -- Filter for top 10 movies per level
ORDER BY 
    rm.production_year DESC, rm.rank;
