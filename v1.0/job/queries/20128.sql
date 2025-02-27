WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank_by_year
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorDetails AS (
    SELECT 
        a.id AS actor_id,
        a.person_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(COALESCE(CAST(minfo.info AS INTEGER), 0)) AS avg_movie_rating
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        movie_info minfo ON ci.movie_id = minfo.movie_id
    WHERE 
        minfo.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY 
        a.id, a.person_id, a.name
),
CombinedData AS (
    SELECT 
        ad.actor_id,
        ad.name,
        ad.movie_count,
        rt.title,
        rt.production_year,
        CASE 
            WHEN ad.avg_movie_rating IS NULL THEN 'No Rating'
            WHEN ad.avg_movie_rating < 5 THEN 'Low Rated'
            WHEN ad.avg_movie_rating BETWEEN 5 AND 7 THEN 'Moderate Rated'
            ELSE 'Highly Rated'
        END AS rating_category
    FROM 
        ActorDetails ad
    JOIN 
        RankedTitles rt ON ad.movie_count > 0
)
SELECT 
    cd.actor_id,
    cd.name,
    cd.movie_count,
    cd.title,
    CASE 
        WHEN cd.production_year >= 2000 THEN '21st Century'
        WHEN cd.production_year IS NULL THEN 'Unknown Year'
        ELSE '20th Century'
    END AS century,
    cd.rating_category,
    COALESCE(ci.kind, 'Unknown Role') AS role
FROM 
    CombinedData cd
LEFT JOIN 
    comp_cast_type ci ON ci.id = (SELECT ci2.person_role_id FROM cast_info ci2 WHERE ci2.person_id = cd.actor_id LIMIT 1)
WHERE 
    cd.rating_category != 'No Rating'
ORDER BY 
    cd.movie_count DESC, cd.production_year DESC;
