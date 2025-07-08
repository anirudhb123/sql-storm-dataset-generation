
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        mt.episode_of_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        mh.level + 1,
        mt.episode_of_id
    FROM 
        aka_title mt
    JOIN 
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
KeywordRanking AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        DENSE_RANK() OVER (PARTITION BY mk.movie_id ORDER BY COUNT(mk.keyword_id) DESC) AS rank
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        LISTAGG(CONCAT(ak.name, ' (', rt.role, ')'), ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
),
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS total_companies,
        LISTAGG(cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cd.total_cast, 0) AS total_cast_members,
    COALESCE(kd.keyword, 'No Keywords') AS primary_keyword,
    COALESCE(kd.rank, 0) AS keyword_rank,
    COALESCE(ci.total_companies, 0) AS total_companies,
    COALESCE(ci.company_names, 'No Companies') AS company_list,
    mh.level AS hierarchy_level
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastDetails cd ON mh.movie_id = cd.movie_id
LEFT JOIN 
    KeywordRanking kd ON mh.movie_id = kd.movie_id AND kd.rank = 1
LEFT JOIN 
    MovieCompanyInfo ci ON mh.movie_id = ci.movie_id
ORDER BY 
    mh.production_year DESC, mh.title;
