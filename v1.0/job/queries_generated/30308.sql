WITH RECURSIVE ParentCTE AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT cc.person_id) AS actor_count,
        COALESCE(MAX(ca.role_id), 0) AS max_role_id
    FROM 
        complete_cast c
    LEFT JOIN cast_info ca ON c.subject_id = ca.person_id
    LEFT JOIN aka_title at ON ca.movie_id = at.movie_id
    LEFT JOIN aka_name an ON ca.person_id = an.person_id
    LEFT JOIN movie_info mi ON ca.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'release_date')
        AND COALESCE(an.name, '') <> ''
    GROUP BY 
        c.movie_id
    UNION ALL
    SELECT 
        p.movie_id,
        p.actor_count,
        p.max_role_id
    FROM 
        ParentCTE p
    INNER JOIN complete_cast cc ON p.movie_id = cc.movie_id
    WHERE 
        p.actor_count < 10
),

MovieInfoWithKeywords AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        coalesce(k.keyword, 'No Keywords') AS keyword,
        COUNT(k.keyword_id) OVER (PARTITION BY m.id) AS keyword_count
    FROM
        aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
),

FinalOutput AS (
    SELECT
        p.movie_id,
        p.actor_count,
        p.max_role_id,
        m.title,
        m.production_year,
        m.keyword,
        m.keyword_count
    FROM 
        ParentCTE p
    JOIN MovieInfoWithKeywords m ON p.movie_id = m.movie_id
    WHERE 
        p.actor_count > 5 AND
        p.max_role_id IN (SELECT id FROM role_type WHERE role ILIKE 'lead%')
)

SELECT 
    COUNT(*) AS total_movies,
    AVG(actor_count) AS average_actor_count,
    STRING_AGG(DISTINCT title, ', ') AS titles_list,
    MIN(production_year) AS earliest_production_year,
    MAX(production_year) AS latest_production_year
FROM 
    FinalOutput
WHERE 
    keyword_count > 1
ORDER BY 
    total_movies DESC;

