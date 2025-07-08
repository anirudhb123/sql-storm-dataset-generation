
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        tk.keyword AS title_keyword,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword tk ON mk.keyword_id = tk.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, tk.keyword
),
TopTitles AS (
    SELECT 
        title_id,
        title,
        production_year,
        title_keyword,
        RANK() OVER (PARTITION BY title_keyword ORDER BY cast_count DESC) AS rank
    FROM 
        RankedTitles
),
TopCast AS (
    SELECT 
        a.name AS actor_name,
        a.person_id,
        c.movie_id,
        t.title,
        t.production_year,
        t.title_keyword
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        TopTitles t ON c.movie_id = t.title_id
    WHERE 
        t.rank <= 5
)
SELECT 
    tc.actor_name,
    tc.title,
    tc.production_year,
    tk.keyword
FROM 
    TopCast tc
JOIN 
    movie_info mi ON tc.movie_id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
JOIN 
    keyword tk ON tc.title_keyword = tk.keyword
WHERE 
    it.info LIKE '%awards%'
ORDER BY 
    tc.production_year DESC, tc.actor_name;
