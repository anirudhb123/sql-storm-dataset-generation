
WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        RANK() OVER (PARTITION BY a.kind_id ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
TopRankedTitles AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedTitles 
    WHERE 
        year_rank <= 5
),
PersonMovies AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    JOIN 
        TopRankedTitles t ON c.movie_id = (SELECT id FROM aka_title WHERE title = t.title LIMIT 1)
    GROUP BY 
        c.person_id
    HAVING 
        COUNT(DISTINCT c.movie_id) > 1
),
PersonNames AS (
    SELECT 
        p.name,
        p.gender
    FROM 
        name p
    JOIN 
        PersonMovies pm ON p.imdb_id = pm.person_id
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keyword_list
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    pn.name AS actor_name,
    pn.gender AS actor_gender,
    COUNT(DISTINCT ci.movie_id) AS collaboration_count,
    COALESCE(mk.keyword_list, 'No Keywords') AS keywords
FROM 
    PersonNames pn
LEFT JOIN 
    cast_info ci ON ci.person_id = (SELECT imdb_id FROM name WHERE name = pn.name LIMIT 1)
LEFT JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id
LEFT JOIN 
    movie_companies mc ON cc.movie_id = mc.movie_id
LEFT JOIN 
    MovieKeywords mk ON mc.movie_id = mk.movie_id
LEFT JOIN 
    aka_title t ON t.id = ci.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
GROUP BY 
    pn.name, pn.gender, mk.keyword_list
ORDER BY 
    collaboration_count DESC, actor_name;
