WITH MovieCast AS (
    SELECT 
        t.title AS movie_title,
        c.person_id,
        a.name AS actor_name,
        a.surname_pcode,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS actor_order
    FROM
        aka_title t
    JOIN cast_info c ON t.id = c.movie_id
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE
        t.production_year >= 1990
    AND a.name IS NOT NULL
),

MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword m
    JOIN keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),

FilteredMovies AS (
    SELECT 
        mc.movie_title,
        mc.actor_name,
        mk.keywords,
        COUNT(*) OVER() AS total_actor_count
    FROM 
        MovieCast mc
    LEFT JOIN MovieKeywords mk ON mc.movie_title = mk.movie_id
    WHERE 
        mc.actor_order <= 3
        AND mc.surname_pcode IS NOT NULL
        AND EXISTS (
            SELECT 1 
            FROM movie_info mi 
            WHERE mi.movie_id = mc.movie_title 
            AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')
            AND mi.info <> ''
        )
),

AggregatedData AS (
    SELECT 
        movie_title,
        COUNT(actor_name) AS actor_count,
        MAX(total_actor_count) AS max_actor_count,
        MIN(total_actor_count) AS min_actor_count,
        ARRAY_AGG(DISTINCT keywords) FILTER (WHERE keywords IS NOT NULL) AS unique_keywords
    FROM 
        FilteredMovies
    GROUP BY 
        movie_title
)

SELECT 
    title.movie_title,
    title.actor_count,
    title.max_actor_count,
    title.min_actor_count,
    CASE 
        WHEN title.actor_count = 0 THEN 'No Actors'
        ELSE 'Actors Present'
    END AS actor_presence,
    COALESCE(title.unique_keywords[1], 'No Keywords') AS primary_keyword,
    CASE 
        WHEN title.actor_count > 5 THEN 'More than 5 Actors'
        WHEN title.actor_count BETWEEN 1 AND 5 THEN 'Few Actors'
        ELSE 'No Actors'
    END AS actor_evaluation
FROM 
    AggregatedData title
ORDER BY 
    title.actor_count DESC,
    title.movie_title;
