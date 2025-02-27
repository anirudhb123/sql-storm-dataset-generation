WITH Recursive_Cast AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT ca.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movie_titles
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ca ON a.person_id = ca.person_id
    LEFT JOIN 
        aka_title t ON ca.movie_id = t.movie_id
    GROUP BY 
        a.person_id
), 
Ranked_Movies AS (
    SELECT 
        rc.person_id,
        rc.movie_count,
        rc.movie_titles,
        RANK() OVER (ORDER BY rc.movie_count DESC, rc.person_id) AS movie_rank
    FROM 
        Recursive_Cast rc
),
Top_Actors AS (
    SELECT 
        r.person_id,
        r.movie_count,
        r.movie_titles
    FROM 
        Ranked_Movies r
    WHERE 
        r.movie_count > (
            SELECT AVG(movie_count) FROM Ranked_Movies
        )
)

SELECT 
    a.name AS actor_name,
    ta.movie_count,
    ta.movie_titles,
    COALESCE(
        (SELECT COUNT(*)
         FROM movie_info mi 
         WHERE 
             mi.movie_id IN (SELECT DISTINCT movie_id FROM cast_info ci WHERE ci.person_id = ta.person_id)
             AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Cinematography')), 
        0) AS cinematography_count,
    CASE 
        WHEN ta.movie_count > 10 THEN 'Prolific Actor'
        ELSE 'Emerging Talent'
    END AS actor_status
FROM 
    aka_name a
JOIN 
    Top_Actors ta ON a.person_id = ta.person_id
LEFT JOIN 
    person_info pi ON pi.person_id = a.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Birthdate')
WHERE 
    (pi.info IS NULL OR pi.info LIKE '%1990%') 
ORDER BY 
    ta.movie_count DESC, actor_name;