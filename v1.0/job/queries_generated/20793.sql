WITH RECURSIVE extended_cast AS (
    SELECT 
        c.id AS cast_id,
        c.person_id,
        c.movie_id,
        c.note AS cast_note,
        c.nr_order,
        COALESCE(a.name, 'Unknown') AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL

    UNION ALL

    SELECT 
        c.id,
        c.person_id,
        c.movie_id,
        c.note,
        c.nr_order,
        COALESCE(a.name, 'Unknown') AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        extended_cast ec
    JOIN 
        cast_info c ON ec.movie_id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL AND ec.actor_rank <= 3
),
bullet_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        COUNT(DISTINCT k.id) AS keyword_count,
        MAX(t.production_year) AS latest_year
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title
    HAVING 
        COUNT(DISTINCT k.id) > 1
),
movies_with_bizarreness AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        MIN(m.production_year) AS first_year,
        MAX(m.production_year) AS last_year,
        COUNT(DISTINCT ec.person_id) AS total_actors,
        STRING_AGG(DISTINCT ec.actor_name, ', ') AS actor_list
    FROM 
        bullet_titles m
    JOIN 
        complete_cast cc ON m.title_id = cc.movie_id
    JOIN 
        extended_cast ec ON cc.subject_id = ec.person_id
    GROUP BY 
        m.id, m.title
    HAVING 
        (MAX(m.production_year) - MIN(m.production_year)) >= 10
        AND COUNT(DISTINCT ec.actor_id) > 5
),
final_movies AS (
    SELECT 
        mwb.movie_id,
        mwb.title,
        mwb.first_year,
        mwb.last_year,
        mwb.total_actors,
        mwb.actor_list,
        CASE 
            WHEN mwb.first_year < 2000 THEN 'Classic' 
            WHEN mwb.last_year > 2020 THEN 'Modern' 
            ELSE 'Historical' 
        END AS era,
        NULLIF(mwb.actor_list, '') AS non_null_actor_list
    FROM 
        movies_with_bizarreness mwb
    WHERE 
        mwb.total_actors IS NOT NULL
)
SELECT 
    fm.title,
    fm.first_year,
    fm.last_year,
    fm.total_actors,
    fm.actor_list,
    fm.era,
    CASE 
        WHEN fm.non_null_actor_list IS NOT NULL THEN 'Actors available' 
        ELSE 'No actors available' 
    END AS actor_availability
FROM 
    final_movies fm
ORDER BY 
    fm.total_actors DESC, 
    fm.first_year ASC
LIMIT 50;
