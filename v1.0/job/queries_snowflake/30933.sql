
WITH RECURSIVE MovieHierachy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        CAST(NULL AS STRING) AS parent_movie_title,
        0 AS level
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL

    UNION ALL

    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        mh.title AS parent_movie_title,
        mh.level + 1
    FROM 
        aka_title t
    JOIN 
        MovieHierachy mh ON t.episode_of_id = mh.movie_id
),
AggregateKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
TotalCast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COALESCE(LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name), 'Not Available') AS company_names,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),

FinalOutput AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.parent_movie_title,
        COALESCE(ak.keywords, 'No Keywords') AS keywords,
        COALESCE(tc.total_cast_count, 0) AS total_cast_count,
        COALESCE(mc.company_names, 'No Companies') AS company_names,
        mc.total_companies
    FROM 
        MovieHierachy mh
    LEFT JOIN 
        AggregateKeywords ak ON mh.movie_id = ak.movie_id
    LEFT JOIN 
        TotalCast tc ON mh.movie_id = tc.movie_id
    LEFT JOIN 
        MovieCompanies mc ON mh.movie_id = mc.movie_id
)

SELECT 
    fo.movie_id,
    fo.title,
    fo.production_year,
    fo.parent_movie_title,
    fo.keywords,
    fo.total_cast_count,
    fo.company_names,
    fo.total_companies,
    CASE 
        WHEN fo.total_cast_count > 5 THEN 'Popular'
        WHEN fo.total_cast_count BETWEEN 1 AND 5 THEN 'Moderate'
        ELSE 'Unknown'
    END AS popularity_rating
FROM 
    FinalOutput fo
WHERE 
    fo.production_year >= 2000
ORDER BY 
    fo.production_year DESC,
    fo.total_cast_count DESC;
