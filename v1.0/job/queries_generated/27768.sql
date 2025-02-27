WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.keyword_count,
        ROW_NUMBER() OVER (ORDER BY rt.keyword_count DESC) AS rank
    FROM 
        RankedTitles rt
    WHERE 
        rt.production_year >= 2000
),
ActorParticipation AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT p.id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    GROUP BY 
        ci.movie_id
),
TopActors AS (
    SELECT 
        tp.title_id,
        tp.title,
        tp.production_year,
        aps.actor_count,
        ROW_NUMBER() OVER (ORDER BY aps.actor_count DESC) AS actor_rank
    FROM 
        TopTitles tp
    JOIN 
        ActorParticipation aps ON tp.title_id = aps.movie_id
)
SELECT 
    ta.title,
    ta.production_year,
    ta.keyword_count,
    ta.actor_count,
    CASE 
        WHEN ta.rank <= 10 THEN 'Top 10 Titles by Keywords'
        ELSE 'Other Titles'
    END AS category
FROM 
    TopActors ta
WHERE 
    ta.actor_rank <= 5
ORDER BY 
    ta.keyword_count DESC, 
    ta.actor_count DESC;
