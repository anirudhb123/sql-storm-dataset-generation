WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        kt.id AS movie_id,
        kt.title AS movie_title,
        1 AS level,
        NULL::integer AS parent_id
    FROM aka_title kt
    WHERE kt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        kt.id AS movie_id,
        kt.title AS movie_title,
        mh.level + 1,
        ct.movie_id AS parent_id
    FROM movie_link ml 
    JOIN aka_title kt ON ml.linked_movie_id = kt.id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
AggregatedData AS (
    SELECT 
        m.movie_id,
        m.movie_title,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        AVG(mi.info ->> 'rating') AS avg_rating,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM MovieHierarchy m
    LEFT JOIN complete_cast cc ON m.movie_id = cc.movie_id
    LEFT JOIN cast_info ci ON ci.movie_id = m.movie_id
    LEFT JOIN movie_info mi ON mi.movie_id = m.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    LEFT JOIN movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY m.movie_id, m.movie_title
),
RankedMovies AS (
    SELECT 
        ad.movie_id,
        ad.movie_title,
        ad.actor_count,
        ad.avg_rating,
        ad.keywords,
        ROW_NUMBER() OVER (PARTITION BY ad.actor_count ORDER BY ad.avg_rating DESC) AS rating_rank
    FROM AggregatedData ad
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.actor_count,
    rm.avg_rating,
    rm.keywords
FROM RankedMovies rm
WHERE 
    rm.rating_rank <= 10 AND 
    rm.actor_count > (SELECT AVG(actor_count) FROM AggregatedData)
ORDER BY 
    rm.avg_rating DESC;
