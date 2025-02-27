WITH Actor_Movie_Count AS (
    SELECT 
        a.id AS actor_id, 
        a.name AS actor_name,
        COUNT(c.movie_id) AS movie_count
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    GROUP BY a.id, a.name
),
Recent_Movie_Info AS (
    SELECT 
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        CASE 
            WHEN t.production_year >= 2020 THEN 'Recent'
            ELSE 'Classic'
        END AS movie_age_group,
        COUNT(mk.keyword_id) AS keyword_count
    FROM aka_title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    GROUP BY t.id, t.title, t.production_year
),
Top_Keywords AS (
    SELECT 
        k.id AS keyword_id,
        k.keyword,
        COUNT(mk.movie_id) AS movie_count
    FROM keyword k
    JOIN movie_keyword mk ON k.id = mk.keyword_id
    GROUP BY k.id, k.keyword
    ORDER BY movie_count DESC
    LIMIT 10
)
SELECT 
    AMC.actor_name,
    AMC.movie_count,
    RMI.movie_title,
    RMI.production_year,
    RMI.movie_age_group,
    TK.keyword,
    TK.movie_count AS keyword_movie_count
FROM Actor_Movie_Count AMC
JOIN Recent_Movie_Info RMI ON AMC.movie_count > 5
JOIN movie_keyword MK ON MK.movie_id = RMI.title_id
JOIN Top_Keywords TK ON MK.keyword_id = TK.keyword_id
ORDER BY AMC.movie_count DESC, RMI.production_year DESC;
