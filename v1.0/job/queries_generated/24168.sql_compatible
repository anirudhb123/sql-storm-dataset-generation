
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.title,
        mt.production_year,
        mcl.linked_movie_id,
        1 AS depth
    FROM 
        title mt
    LEFT JOIN 
        movie_link mcl ON mt.id = mcl.movie_id
    WHERE 
        mt.production_year BETWEEN 2000 AND 2020 
        AND mt.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%')

    UNION ALL

    SELECT 
        mt.title,
        mt.production_year,
        mcl.linked_movie_id,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link mcl ON mh.linked_movie_id = mcl.movie_id
    JOIN 
        title mt ON mcl.linked_movie_id = mt.id
    WHERE 
        mh.depth < 3  
        AND mt.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%')
),
ActorDetails AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS titles
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    WHERE 
        ak.name IS NOT NULL 
        AND ci.person_role_id IN (SELECT id FROM role_type WHERE role ILIKE '%lead%')
    GROUP BY 
        ak.name
),
TitleKeywords AS (
    SELECT 
        mt.title, 
        k.keyword,
        COALESCE(k.phonetic_code, 'NULL') AS keyword_phonetic
    FROM 
        title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        mt.production_year >= 2000
)
SELECT 
    mh.title AS movie_title,
    mh.production_year,
    ad.actor_name,
    ad.movie_count,
    tk.keyword AS linked_keyword,
    tk.keyword_phonetic,
    ROW_NUMBER() OVER (PARTITION BY mh.title ORDER BY ad.movie_count DESC) AS rank
FROM 
    MovieHierarchy mh
LEFT JOIN 
    ActorDetails ad ON mh.title = ad.actor_name  
LEFT JOIN 
    TitleKeywords tk ON mh.title = tk.title
WHERE 
    mh.depth = 1
ORDER BY 
    mh.production_year DESC, ad.movie_count DESC, mh.title;
