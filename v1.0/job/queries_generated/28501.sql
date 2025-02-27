WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rank
    FROM aka_title a
    JOIN movie_keyword mk ON a.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE a.production_year >= 2000
),
TopTitles AS (
    SELECT 
        title,
        production_year,
        keyword
    FROM RankedTitles
    WHERE rank = 1
),
ActorInfo AS (
    SELECT 
        ak.name AS actor_name,
        m.title,
        m.production_year,
        c.nr_order,
        r.role
    FROM cast_info c
    JOIN aka_name ak ON c.person_id = ak.person_id
    JOIN aka_title m ON c.movie_id = m.id
    JOIN role_type r ON c.role_id = r.id
    WHERE ak.name IS NOT NULL
),
AggregatedData AS (
    SELECT 
        a.actor_name,
        COUNT(t.title) AS total_titles,
        STRING_AGG(DISTINCT t.keyword, ', ') AS keywords_used
    FROM ActorInfo a
    JOIN TopTitles t ON a.title = t.title
    GROUP BY a.actor_name
)
SELECT 
    actor_name,
    total_titles,
    keywords_used,
    CASE 
        WHEN total_titles > 5 THEN 'Prolific Actor'
        WHEN total_titles BETWEEN 3 AND 5 THEN 'Moderate Actor'
        ELSE 'Newcomer'
    END AS actor_status
FROM AggregatedData
ORDER BY total_titles DESC;
