WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.episode_of_id IS NULL
    UNION ALL
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        aka_title AS mt
    JOIN 
        MovieHierarchy AS mh ON mt.episode_of_id = mh.movie_id
),
AggregatedData AS (
    SELECT 
        c.id AS cast_id,
        ka.name AS actor_name,
        kt.title AS movie_title,
        mh.production_year,
        COUNT(DISTINCT mc.company_id) AS companies_count,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY mh.production_year DESC) AS actor_rank
    FROM 
        cast_info AS c
    JOIN 
        aka_name AS ka ON c.person_id = ka.person_id
    JOIN 
        MovieHierarchy AS mh ON c.movie_id = mh.movie_id
    LEFT JOIN 
        movie_companies AS mc ON mc.movie_id = c.movie_id
    LEFT JOIN 
        movie_keyword AS mk ON mk.movie_id = c.movie_id
    LEFT JOIN 
        keyword AS kw ON mk.keyword_id = kw.id
    GROUP BY 
        c.id, ka.name, kt.title, mh.production_year
)
SELECT 
    ad.actor_name,
    ad.movie_title,
    ad.production_year,
    ad.companies_count,
    ad.keywords,
    COALESCE(ad.actor_rank, 'Not Ranked') AS rank_info
FROM 
    AggregatedData AS ad
WHERE 
    ad.production_year >= 2000
    AND ad.companies_count >= 1
    AND ad.keywords IS NOT NULL
ORDER BY 
    ad.production_year DESC,
    ad.actor_rank;
