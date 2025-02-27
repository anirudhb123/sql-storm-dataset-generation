WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
    AND 
        EXISTS (
            SELECT 1 
            FROM movie_info mi 
            WHERE mi.movie_id = t.id 
            AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'genre')
            AND mi.info LIKE '%Drama%'
        )
),
FilteredTitles AS (
    SELECT 
        rt.actor_name,
        rt.movie_title,
        rt.production_year
    FROM 
        RankedTitles rt
    WHERE 
        rt.rn <= 3  -- Top 3 latest movies per actor
),
ActorMoviePair AS (
    SELECT 
        f.actor_name,
        f.movie_title,
        COALESCE(mk.keyword, 'No Keyword') AS keyword,
        count(mk.keyword) OVER(PARTITION BY f.actor_name) AS keyword_count
    FROM 
        FilteredTitles f
    LEFT JOIN 
        movie_keyword mk ON f.movie_title = mk.movie_id
),
FinalResults AS (
    SELECT 
        amp.actor_name,
        amp.movie_title,
        STRING_AGG(amp.keyword, ', ') AS keywords,
        COUNT(DISTINCT amp.keyword_count) AS unique_keyword_count
    FROM 
        ActorMoviePair amp
    GROUP BY 
        amp.actor_name, amp.movie_title
)
SELECT 
    actor_name,
    movie_title,
    keywords,
    unique_keyword_count,
    CASE 
        WHEN unique_keyword_count = 0 THEN 'No Keywords Available'
        WHEN unique_keyword_count > 5 THEN 'Rich in Keywords'
        ELSE 'Moderate Keywords'
    END AS keyword_quality
FROM 
    FinalResults
ORDER BY 
    actor_name, movie_title;
