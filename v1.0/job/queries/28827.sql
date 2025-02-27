WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
),
ActorDetails AS (
    SELECT 
        a.person_id,
        a.name,
        c.movie_id,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        a.name IS NOT NULL
),
KeywordCounts AS (
    SELECT 
        m.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        m.movie_id
),
MovieInfoAggregated AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS info_details
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    (SELECT COUNT(DISTINCT a.person_id) FROM ActorDetails a WHERE a.movie_id = rt.title_id) AS actor_count,
    (SELECT keyword_count FROM KeywordCounts k WHERE k.movie_id = rt.title_id) AS keyword_count,
    (SELECT info_details FROM MovieInfoAggregated m WHERE m.movie_id = rt.title_id) AS additional_info
FROM 
    RankedTitles rt
WHERE 
    rt.title_rank <= 10
ORDER BY 
    rt.production_year DESC, rt.title;
