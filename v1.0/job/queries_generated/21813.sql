WITH RecursiveRoleHistory AS (
    SELECT 
        ci.person_id,
        rt.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY ci.nr_order) AS role_rank
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) OVER (PARTITION BY mc.movie_id) AS num_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
TitleKeywordInfo AS (
    SELECT
        m.id AS movie_id,
        mt.title AS movie_title,
        STRING_AGG(k.keyword, ', ') AS keywords,
        COUNT(k.id) AS keyword_count
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, mt.title
),
FilteredTitles AS (
    SELECT 
        mt.movie_id,
        mt.movie_title,
        ik.info AS movie_info
    FROM 
        TitleKeywordInfo mt
    LEFT JOIN 
        movie_info ik ON mt.movie_id = ik.movie_id AND ik.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
    WHERE 
        (mt.keyword_count >= 3 AND mt.movie_title IS NOT NULL) 
        OR (mt.movie_title LIKE '%Mystery%' AND ik.info IS NOT NULL)
),
FinalResults AS (
    SELECT 
        ak.name AS actor_name,
        rt.role_name,
        mt.movie_title,
        mc.company_name,
        mc.company_type,
        fi.movie_info,
        RANK() OVER (PARTITION BY ak.person_id ORDER BY mt.movie_title) AS movie_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        RecursiveRoleHistory rt ON ci.person_id = rt.person_id
    JOIN 
        MovieCompanyInfo mc ON ci.movie_id = mc.movie_id 
    JOIN 
        FilteredTitles mt ON ci.movie_id = mt.movie_id 
    LEFT JOIN 
        movie_info fi ON mt.movie_id = fi.movie_id
    WHERE 
        ak.name IS NOT NULL
        AND (mc.num_companies > 2 OR fi.info IS NOT NULL)
)
SELECT 
    *,
    CASE 
        WHEN movie_rank = 1 THEN 'Leading Role'
        WHEN movie_rank < 5 AND movie_rank > 1 THEN 'Supporting Role'
        ELSE 'Background Role'
    END AS role_description
FROM 
    FinalResults
WHERE 
    movie_title IS NOT NULL
ORDER BY 
    actor_name, movie_title;
