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
), ActorAwardInfo AS (
    SELECT 
        p.person_id,
        COUNT(DISTINCT p.info_type_id) AS award_count
    FROM 
        person_info p
    JOIN 
        info_type i ON p.info_type_id = i.id
    WHERE 
        i.info LIKE '%Award%'
    GROUP BY 
        p.person_id
), TitleKeyword AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.movie_id
    GROUP BY 
        mt.movie_id
)
SELECT 
    rt.actor_name,
    rt.movie_title,
    rt.production_year,
    COALESCE(aki.award_count, 0) AS award_count,
    COALESCE(tk.keywords, 'None') AS keywords
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorAwardInfo aki ON rt.actor_name = (SELECT name FROM aka_name a WHERE a.person_id = aki.person_id LIMIT 1)
LEFT JOIN 
    TitleKeyword tk ON rt.movie_title = (SELECT title FROM aka_title t WHERE t.movie_id = tk.movie_id LIMIT 1)
WHERE 
    rt.rn = 1
ORDER BY 
    rt.production_year DESC, 
    rt.actor_name;
