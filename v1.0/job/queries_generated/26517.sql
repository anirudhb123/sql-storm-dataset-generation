WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM 
        title t
    WHERE 
        t.production_year > 2000
),
AkaNames AS (
    SELECT 
        ak.person_id,
        ak.name,
        ak.id AS aka_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    GROUP BY 
        ak.person_id, ak.name, ak.id
),
TopActors AS (
    SELECT 
        an.name,
        an.movie_count,
        ROW_NUMBER() OVER (ORDER BY an.movie_count DESC) AS actor_rank
    FROM 
        AkaNames an
    WHERE 
        an.movie_count > 5
),
Keywords AS (
    SELECT 
        k.id AS keyword_id,
        k.keyword
    FROM 
        keyword k
    WHERE 
        k.phonetic_code IS NOT NULL
),
MoviesWithKeywords AS (
    SELECT 
        mt.movie_id, 
        mt.title,
        mk.keyword_id,
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        movie_info m ON mk.movie_id = m.movie_id
    JOIN 
        title mt ON mt.id = mk.movie_id
    JOIN 
        Keywords k ON mk.keyword_id = k.keyword_id
)
SELECT 
    t.title,
    t.production_year,
    a.name AS actor_name,
    tk.keyword,
    rt.rank AS title_rank
FROM 
    RankedTitles rt
JOIN 
    MoviesWithKeywords tk ON rt.title_id = tk.movie_id
JOIN 
    cast_info ci ON ci.movie_id = rt.title_id
JOIN 
    TopActors a ON a.name = (SELECT ak.name FROM aka_name ak WHERE ak.person_id = ci.person_id LIMIT 1)
WHERE 
    rt.rank <= 3
ORDER BY 
    rt.production_year DESC, a.movie_count DESC;

This query first ranks titles based on their production year for those produced after 2000. Then, it summarizes and ranks actors based on the number of movies they've appeared in, filtering for those with more than 5 movies. It further joins with keywords and filters results to include only the top-ranked titles (up to 3) along with corresponding actor names and keywords, ordered by production year and actor movie count for insightful benchmarking of string processing across various relations.
