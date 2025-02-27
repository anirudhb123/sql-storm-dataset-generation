
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        title t
    JOIN 
        aka_title at ON t.id = at.movie_id
    JOIN 
        cast_info c ON at.movie_id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopTitles AS (
    SELECT 
        title_id, 
        title, 
        production_year, 
        actor_count,
        RANK() OVER (ORDER BY actor_count DESC) AS rank
    FROM 
        RankedTitles
)
SELECT 
    tt.title,
    tt.production_year,
    tt.actor_count,
    STRING_AGG(aka.name, ', ') AS actor_names,
    GROUP_CONCAT(DISTINCT kw.keyword) AS keywords 
FROM 
    TopTitles tt
JOIN 
    cast_info ci ON tt.title_id = ci.movie_id
JOIN 
    aka_name aka ON ci.person_id = aka.person_id
LEFT JOIN 
    movie_keyword mk ON tt.title_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    tt.rank <= 10
GROUP BY 
    tt.title, tt.production_year, tt.actor_count
ORDER BY 
    tt.actor_count DESC;
