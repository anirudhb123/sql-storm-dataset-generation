WITH movie_ratings AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        COALESCE(AVG(r.rating), 0) AS avg_rating
    FROM 
        aka_title m
    LEFT JOIN 
        ratings r ON m.id = r.movie_id
    GROUP BY 
        m.id
),
actor_details AS (
    SELECT 
        c.movie_id, 
        a.name AS actor_name,
        COUNT(CASE WHEN c.note IS NULL THEN 1 END) AS null_note_count,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        c.movie_id, a.name
),
movie_details AS (
    SELECT 
        t.id AS title_id, 
        t.title AS movie_title, 
        COALESCE(mr.avg_rating, 0) AS average_rating,
        COALESCE(cd.actor_count, 0) AS num_actors,
        CASE 
            WHEN mr.avg_rating > 8 THEN 'Highly Rated'
            WHEN mr.avg_rating BETWEEN 5 AND 8 THEN 'Moderately Rated'
            ELSE 'Poorly Rated'
        END AS rating_category
    FROM 
        aka_title t
    LEFT JOIN 
        movie_ratings mr ON t.id = mr.movie_id
    LEFT JOIN (
        SELECT 
            movie_id, 
            COUNT(DISTINCT person_id) AS actor_count
        FROM 
            cast_info 
        GROUP BY 
            movie_id
    ) AS cd ON t.id = cd.movie_id
)
SELECT 
    md.movie_title,
    md.average_rating,
    md.rating_category,
    ad.actor_name,
    ad.null_note_count
FROM 
    movie_details md
LEFT JOIN 
    actor_details ad ON md.title_id = ad.movie_id
WHERE 
    md.num_actors > 0
ORDER BY 
    md.average_rating DESC, 
    ad.actor_order
FETCH FIRST 10 ROWS ONLY;

-- Include more bizarre semantics by examining titles with phonetic similarities in names
WITH phonetic_names AS (
    SELECT 
        c.movie_id, 
        STRING_AGG(DISTINCT a.name, ', ') AS phonetic_actors,
        UPPER(SUBSTRING(a.name, 1, 1)) AS name_initial
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name_pcode_nf IS NOT NULL
    GROUP BY 
        c.movie_id, UPPER(SUBSTRING(a.name, 1, 1))
)
SELECT 
    md.movie_title,
    pn.phonetic_actors
FROM 
    movie_details md
JOIN 
    phonetic_names pn ON md.title_id = pn.movie_id
WHERE 
    pn.name_initial = 'A'
ORDER BY 
    md.average_rating DESC;
