WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        id AS movie_id,
        title,
        production_year,
        episode_of_id,
        season_nr,
        episode_nr,
        1 AS level
    FROM 
        title
    WHERE 
        episode_of_id IS NULL
    UNION ALL
    SELECT 
        t.id,
        t.title,
        t.production_year,
        t.episode_of_id,
        t.season_nr,
        t.episode_nr,
        mh.level + 1
    FROM 
        title t
    JOIN 
        MovieHierarchy mh ON t.episode_of_id = mh.movie_id
),
TopKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        ROW_NUMBER() OVER(PARTITION BY mk.movie_id ORDER BY COUNT(mk.keyword_id) DESC) AS keyword_rank
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
),
CastInfoWithRoles AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        rt.role
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
MovieCompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    mh.title AS movie_title,
    mh.production_year,
    string_agg(DISTINCT k.keyword) FILTER (WHERE k.keyword IS NOT NULL) AS keywords,
    STRING_AGG(DISTINCT c.company_name || ' (' || c.company_type || ')') AS companies,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    AVG(CASE WHEN YEAR(NOW()) - mh.production_year < 10 THEN 1 ELSE 0 END) AS avg_recently_released,
    COUNT(DISTINCT CASE WHEN ci.note IS NOT NULL THEN ci.person_id END) AS cast_with_notes,
    MAX(mh.level) OVER() AS max_hierarchy_level
FROM 
    MovieHierarchy mh
LEFT JOIN 
    TopKeywords k ON mh.movie_id = k.movie_id AND k.keyword_rank <= 3
LEFT JOIN 
    MovieCompanyDetails c ON mh.movie_id = c.movie_id
LEFT JOIN 
    CastInfoWithRoles ci ON mh.movie_id = ci.movie_id
WHERE 
    mh.production_year IS NOT NULL
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
ORDER BY 
    mh.production_year DESC, total_cast DESC;
