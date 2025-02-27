WITH RecursiveMovieCTE AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rn
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
ActorInfo AS (
    SELECT 
        p.person_id,
        a.name,
        a.surname_pcode,
        COUNT(c.movie_id) AS movie_count,
        AVG(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS average_note_presence
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    LEFT JOIN 
        person_info pi ON pi.person_id = a.person_id
    GROUP BY 
        p.person_id, a.name, a.surname_pcode
),
MoviesWithKeywords AS (
    SELECT 
        m.title,
        k.keyword,
        COUNT(mk.movie_id) AS keyword_count
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.title, k.keyword
),
MoviesLinks AS (
    SELECT 
        ml.movie_id,
        COUNT(ml.linked_movie_id) AS num_links
    FROM 
        movie_link ml
    GROUP BY 
        ml.movie_id
)

SELECT 
    r.rn,
    r.title,
    r.production_year,
    ai.name,
    ai.surname_pcode,
    COALESCE(ai.movie_count, 0) AS total_movies,
    COALESCE(kw.keyword, 'No Keyword') AS keyword,
    COALESCE(kw.keyword_count, 0) AS keyword_occurrences,
    COALESCE(ml.num_links, 0) AS linked_movies,
    CASE 
        WHEN ai.average_note_presence IS NULL THEN 'Unknown' 
        WHEN ai.average_note_presence > 0.5 THEN 'Prominent' 
        ELSE 'Minor' 
    END AS actor_visibility
FROM 
    RecursiveMovieCTE r
LEFT JOIN 
    ActorInfo ai ON r.movie_id = ai.person_id
LEFT JOIN 
    MoviesWithKeywords kw ON r.title = kw.title
LEFT JOIN 
    MoviesLinks ml ON r.movie_id = ml.movie_id
WHERE 
    r.production_year > 2000 
    AND (ai.total_movies > 5 OR r.production_year BETWEEN 2020 AND 2023)
ORDER BY 
    r.production_year DESC, ai.name, r.title;
