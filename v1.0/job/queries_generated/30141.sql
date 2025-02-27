WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') -- Adjusting for movie kind

    UNION ALL

    SELECT 
        m.id,
        CONCAT(parent.title, ' -> ', child.title) AS title,
        level + 1
    FROM 
        MovieHierarchy parent
    JOIN 
        aka_title child ON child.episode_of_id = parent.movie_id
), 

CastStats AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS total_cast,
        COUNT(DISTINCT c.person_role_id) AS unique_roles
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
), 

TitleInfo AS (
    SELECT 
        a.title, 
        a.production_year,
        COALESCE(NULLIF(mk.keyword, ''), 'No Keywords') AS keyword,
        COALESCE(NULLIF(pi.info, ''), 'No Info') AS person_information
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = a.id
    LEFT JOIN 
        movie_info pi ON pi.movie_id = a.id
), 

JoinOrder AS (
    SELECT 
        mh.movie_id,
        mh.title,
        ts.production_year,
        cs.total_cast,
        cs.unique_roles
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        TitleInfo ts ON ts.title = mh.title
    LEFT JOIN 
        CastStats cs ON cs.movie_id = mh.movie_id
) 

SELECT 
    jo.movie_id,
    jo.title,
    jo.production_year,
    jo.total_cast,
    jo.unique_roles,
    RANK() OVER (PARTITION BY jo.production_year ORDER BY jo.total_cast DESC) AS rank_within_year,
    CASE
        WHEN jo.total_cast IS NULL THEN 'No Cast'
        ELSE 'Has Cast'
    END AS cast_status
FROM 
    JoinOrder jo
WHERE 
    jo.unique_roles > 1
ORDER BY 
    jo.production_year DESC, jo.total_cast DESC;
