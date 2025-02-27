WITH RECURSIVE MovieHierarchy AS (
    -- CTE to find all movies and their associated titles
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    UNION ALL
    SELECT 
        mh.movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        aka_title mt ON mh.movie_id = mt.episode_of_id
),
TitleWithCast AS (
    -- CTE to get titles with their corresponding cast and respective roles
    SELECT 
        t.title,
        t.production_year,
        c.person_id,
        r.role
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
),
UniqueKeywords AS (
    -- CTE to get unique keywords for movies
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CompanyInfo AS (
    -- CTE to fetch company names and their types for movies
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
SelectedMovies AS (
    -- CTE to get selected movies based on complex predicates
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(distinct tc.person_id) AS cast_count,
        MAX(ci.note) AS latest_note,
        COALESCE(uk.keywords, 'None') AS movie_keywords,
        COALESCE(ci.company_name, 'Not Available') AS company_name,
        COALESCE(ci.company_type, 'Not Listed') AS company_type
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        TitleWithCast tc ON mh.movie_id = tc.movie_id
    LEFT JOIN 
        UniqueKeywords uk ON mh.movie_id = uk.movie_id
    LEFT JOIN 
        CompanyInfo ci ON mh.movie_id = ci.movie_id
    WHERE 
        mh.production_year > 2000
        AND (mh.kind_id = 1 OR mh.kind_id = 2) -- Assuming 1 = Movie, 2 = TV
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
    HAVING 
        COUNT(tc.person_id) > 5
        AND MAX(ci.note) IS NOT NULL
)
SELECT 
    sm.title,
    sm.production_year,
    sm.cast_count,
    sm.latest_note,
    sm.movie_keywords,
    sm.company_name,
    sm.company_type
FROM 
    SelectedMovies sm
ORDER BY 
    sm.production_year DESC, 
    sm.cast_count DESC
LIMIT 10;
