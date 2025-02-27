WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
),
TitleKwd AS (
    SELECT 
        rt.actor_name,
        rt.movie_title,
        rt.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY rt.movie_title ORDER BY k.keyword) AS keyword_rank
    FROM 
        RankedTitles rt
    JOIN 
        movie_keyword mk ON rt.movie_title = (SELECT title FROM aka_title WHERE movie_id = mk.movie_id)
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
ActorInfo AS (
    SELECT 
        rt.actor_name,
        STRING_AGG(DISTINCT p.info, ', ') AS actor_info
    FROM 
        RankedTitles rt
    JOIN 
        person_info p ON rt.actor_name = (SELECT name FROM aka_name WHERE person_id = p.person_id)
    GROUP BY 
        rt.actor_name
)
SELECT 
    tk.actor_name,
    tk.movie_title,
    tk.production_year,
    tk.keyword,
    ai.actor_info
FROM 
    TitleKwd tk
JOIN 
    ActorInfo ai ON tk.actor_name = ai.actor_name
WHERE 
    tk.title_rank <= 10 AND tk.keyword_rank <= 5
ORDER BY 
    tk.production_year DESC, tk.movie_title, tk.keyword;
